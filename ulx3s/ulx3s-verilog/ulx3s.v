
/******************************************************************************/
// A lot of RISC-V on the ULX3S
/******************************************************************************/

`default_nettype none // Makes it easier to detect typos !

`include "../../common-verilog/femtorv32_gracilis.v"
`include "../../common-verilog/uart-fifo.v"
`include "../../common-verilog/MappedSPIFlash.v"
`include "../../common-verilog/ringoscillator-ecp5.v"
`include "../../common-verilog/sdram/muchtoremember.v"

`include "../../common-verilog/usb_cdc/bulk_endp.v"
`include "../../common-verilog/usb_cdc/ctrl_endp.v"
`include "../../common-verilog/usb_cdc/in_fifo.v"
`include "../../common-verilog/usb_cdc/out_fifo.v"
`include "../../common-verilog/usb_cdc/phy_rx.v"
`include "../../common-verilog/usb_cdc/phy_tx.v"
`include "../../common-verilog/usb_cdc/sie.v"
`include "../../common-verilog/usb_cdc/usb_cdc.v"

`include "TMDS_encoder.v"

module ulx3s(

  input clk_25mhz,
  input [6:0] btn,
   output [7:0] led,

  output wifi_gpio0,
  output wifi_en,

  inout [27:0] gp,
  inout [27:0] gn,

  output flash_csn,
  // output flash_clk, // This is a special pin on ECP5 and requires using the USRMCLK macro.
  inout  flash_mosi,   // IO0
  inout  flash_miso,   // IO1
  output flash_wpn,    // IO2
  output flash_holdn,  // IO3

  output adc_sclk,
  output adc_csn,
  output adc_mosi,
  input  adc_miso,

  output sd_cmd,
  output sd_clk,
  output sd_d3,
  input  sd_d0,

  output [3:0] audio_l,
  output [3:0] audio_r,
  output [3:0] audio_v,

  inout oled_clk,
  inout oled_mosi,
  inout oled_resn,
  inout oled_dc,
  inout oled_csn,

  output ftdi_rxd, // UART TX
  input  ftdi_txd, // UART RX

  inout  usb_fpga_bd_dp,
  inout  usb_fpga_bd_dn,
  output usb_fpga_pu_dp,

  output sdram_csn,       // chip select
  output sdram_clk,       // clock to SDRAM
  output sdram_cke,       // clock enable to SDRAM
  output sdram_rasn,      // SDRAM RAS
  output sdram_casn,      // SDRAM CAS
  output sdram_wen,       // SDRAM write-enable
  output [12:0] sdram_a,  // SDRAM address bus
  output [1:0] sdram_ba,  // SDRAM bank-address
  output [1:0] sdram_dqm, // byte select
  inout [15:0] sdram_d,   // data bus to/from SDRAM

   output [3:0] gpdi_dp   // 0: blue 1: green 2: red 3: pixel clock
                          // gpdi_dn[3:0] generated automatically
                          // using IO_TYPE=LVCMOS33D in ulx3s_v20.lpf
                          // (D=Differential)
);

   /***************************************************************************/
   // Clock.
   /***************************************************************************/

   wire clk = pixclk; // Use pixel clock as main clock
   wire pll_locked40 = pixclk_locked;
   // pll40 _pll_clk( .clkin(clk_25mhz), .clkout0(clk), .locked(pll_locked40) );  // 40 MHz

   wire clk_48mhz;
   wire pll_locked48;
   pll48 _pll_usb( .clkin(clk_25mhz), .clkout0(clk_48mhz), .locked(pll_locked48) );  // 48 MHz

   wire pll_locked = pll_locked40 & pll_locked48;

   // Tie GPIO0 high, keep board from rebooting
   assign wifi_gpio0 = 1;

   // Cut off wifi_en
   assign wifi_en = 0;

   /***************************************************************************/
   // Reset logic.
   /***************************************************************************/

   reg [7:0] reset_cnt = 0;
   wire resetq = &reset_cnt;

   always @(posedge clk) begin
     if (btn[0] & pll_locked) reset_cnt <= reset_cnt + !resetq;
     else                     reset_cnt <= 0;
   end

   /***************************************************************************/
   // LEDs.
   /***************************************************************************/

   reg [7:0] LEDs;
   assign led = LEDs;

   /***************************************************************************/
   // Ring oscillator for random numbers.
   /***************************************************************************/

   wire random;
   ring_osc #( .NUM_LUTS(1) ) chaos ( .osc_out(random), .resetq(resetq) );

   /***************************************************************************/
   // Timer with interrupt.
   /***************************************************************************/

   reg  interrupt = 0;
   reg  [31:0] ticks;
   wire [32:0] ticks_plus_1 = ticks + 1;
   reg  [31:0] reload = 0;
   wire [31:0] next_ticks = ticks_plus_1[32] ? reload[31:0] : ticks_plus_1[31:0];

   always @(posedge clk)
   begin
     if (io_wstrb & mem_address[IO_Ticks_bit])  ticks  <= mem_wdata; else ticks <= next_ticks;
     if (io_wstrb & mem_address[IO_Reload_bit]) reload <= mem_wdata;

     interrupt <= ticks_plus_1[32]; // Generate interrupt on ticks overflow
   end

   /***************************************************************************/
   // GPIO.
   /***************************************************************************/

   wire [27:0] porta_in;
   reg  [31:0] porta_out;
   reg  [31:0] porta_dir;  // 1:output, 0:input

   wire [27:0] portb_in;
   reg  [31:0] portb_out;
   reg  [31:0] portb_dir;  // 1:output, 0:input

   BB ioa [27:0] (.B(gp[27:0]), .I(porta_out[27:0]), .O(porta_in[27:0]), .T(~porta_dir[27:0]));
   BB iob [27:0] (.B(gn[27:0]), .I(portb_out[27:0]), .O(portb_in[27:0]), .T(~portb_dir[27:0]));

   wire [6:0] buttons_in = {random, btn[6:1]};

   /***************************************************************************/
   // UART.
   /***************************************************************************/

   wire serial_valid, serial_busy;
   wire [7:0] serial_data;
   wire serial_wr = io_wstrb & mem_address[IO_UART_DAT_bit];
   wire serial_rd = io_rstrb & mem_address[IO_UART_DAT_bit];

   buart #(
     .FREQ_MHZ(40),
     .BAUDS(115200)
   ) buart (
      .clk(clk),
      .resetq(resetq),
      .rx(ftdi_txd),
      .tx(ftdi_rxd),
      .rd(serial_rd),
      .wr(serial_wr),
      .valid(serial_valid),
      .busy(serial_busy),
      .tx_data(mem_wdata[7:0]),
      .rx_data(serial_data)
   );

   /***************************************************************************/
   // USB Terminal.
   /***************************************************************************/

   wire usb_valid, usb_ready, usb_configured;
   wire [7:0] usb_data;
   wire usb_wr = io_wstrb & mem_address[IO_USB_DAT_bit];
   wire usb_rd = io_rstrb & mem_address[IO_USB_DAT_bit];

   usb_cdc #(.IN_BULK_MAXPACKETSIZE('d64), .OUT_BULK_MAXPACKETSIZE('d64), .VENDORID(16'h0483), .PRODUCTID(16'h5740), .USE_APP_CLK(1), .APP_CLK_FREQ(40)) _terminal
   (
     // Part running on 48 MHz:

     .clk_i(clk_48mhz),

     .dp_pu_o(usb_pullup),
     .tx_en_o(usb_tx_en),
     .dp_tx_o(usb_p_tx),
     .dn_tx_o(usb_n_tx),
     .dp_rx_i(usb_p_rx),
     .dn_rx_i(usb_n_rx),

     // Part running on 40 MHz:

     .app_clk_i(clk),
     .rstn_i(pll_locked), // Keep connection alive, only reset when PLL is trying to lock.
     .configured_o(usb_configured),

     .out_data_o(usb_data),
     .out_valid_o(usb_valid),
     .out_ready_i(usb_rd),

     .in_data_i(mem_wdata[7:0]),
     .in_ready_o(usb_ready),
     .in_valid_i(usb_wr)
   );

   wire usb_p_tx;
   wire usb_n_tx;
   wire usb_p_rx;
   wire usb_n_rx;
   wire usb_tx_en;
   wire usb_pullup;

   wire usb_p_in;
   wire usb_n_in;

   assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_in;
   assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_in;

   // T = TRISTATE (not transmit)
   BB io_p( .I( usb_p_tx ), .T( !usb_tx_en ), .O( usb_p_in ), .B( usb_fpga_bd_dp ) );
   BB io_n( .I( usb_n_tx ), .T( !usb_tx_en ), .O( usb_n_in ), .B( usb_fpga_bd_dn ) );

   assign usb_fpga_pu_dp = usb_pullup ? 1'b1 : 1'bz;

   /***************************************************************************/
   // OLED.
   /***************************************************************************/

   wire [4:0] oled_in;
   reg  [4:0] oled_out;
   reg  [4:0] oled_dir;   // 1:output, 0:input

   BBPU oled0  (.B(oled_clk  ), .I(oled_out[ 0]), .O(oled_in[ 0]), .T(~oled_dir[ 0]));
   BBPU oled1  (.B(oled_mosi ), .I(oled_out[ 1]), .O(oled_in[ 1]), .T(~oled_dir[ 1]));
   BBPU oled2  (.B(oled_resn ), .I(oled_out[ 2]), .O(oled_in[ 2]), .T(~oled_dir[ 2]));
   BBPU oled3  (.B(oled_dc   ), .I(oled_out[ 3]), .O(oled_in[ 3]), .T(~oled_dir[ 3]));
   BBPU oled4  (.B(oled_csn  ), .I(oled_out[ 4]), .O(oled_in[ 4]), .T(~oled_dir[ 4]));

   /***************************************************************************/
   // ADC.
   /***************************************************************************/

   wire      adc_in = adc_miso;
   reg [2:0] adc_out;

   assign {adc_csn, adc_sclk, adc_mosi} = adc_out;

   /***************************************************************************/
   // SD-Card.
   /***************************************************************************/

   wire       sd_in = sd_d0; // MISO
   reg  [2:0] sd_out;

   assign {sd_d3, sd_clk, sd_cmd} = sd_out[2:0]; // CS, SCLK, MOSI

   /***************************************************************************/
   // Analog out.
   /***************************************************************************/

   reg [11:0] analog_out;

   assign audio_l = analog_out[3:0];
   assign audio_r = analog_out[7:4];
   assign audio_v = analog_out[11:8];

   /***************************************************************************/
   // IO Ports.
   /***************************************************************************/

   // We got a total of 30 bits for 1-hot addressing of IO registers.

   // Bits mem_address[1:0] : Byte select
   // Bits mem_address[3:2] : Write +0, Clear +4, Set +8, Toggle +12

   localparam IO_PORTA_IN_bit    =  4; // R:  GPIO port in
   localparam IO_PORTA_OUT_bit   =  5; // RW: GPIO port out
   localparam IO_PORTA_DIR_bit   =  6; // RW: GPIO port dir
   localparam IO_LEDS_bit        =  7; // RW: Eight leds

   localparam IO_PORTB_IN_bit    =  8; // R:  GPIO port in
   localparam IO_PORTB_OUT_bit   =  9; // RW: GPIO port out
   localparam IO_PORTB_DIR_bit   = 10; // RW: GPIO port dir
   localparam IO_BUTTONS_IN_bit  = 11; // R:  Six buttons and random

   localparam IO_OLED_IN_bit     = 12; // R:  OLED in
   localparam IO_OLED_OUT_bit    = 13; // RW: OLED out
   localparam IO_OLED_DIR_bit    = 14; // RW: OLED dir
   localparam IO_ANALOG_OUT_bit  = 15; // RW: 3 * 4 Bit DAC

   localparam IO_UART_DAT_bit    = 16; // RW write: data to send (8 bits) read: received data (8 bits)
   localparam IO_UART_CNTL_bit   = 17; // R  status. bit 8: valid read data. bit 9: busy sending
   localparam IO_Ticks_bit       = 18; // RW: Timer count register
   localparam IO_Reload_bit      = 19; // RW: Timer reload value

   localparam IO_ADC_IN_bit      = 20; // R:  ADC in
   localparam IO_ADC_OUT_bit     = 21; // RW: ADC out
   localparam IO_SD_IN_bit       = 22; // R:  SD-Card in
   localparam IO_SD_OUT_bit      = 23; // RW: SD-Card out

   localparam IO_USB_DAT_bit     = 24; // RW write: data to send (8 bits) read: received data (8 bits)
   localparam IO_USB_CNTL_bit    = 25; // R  status. bit 8: valid read data. bit 9: busy sending

   wire [31:0] io_rdata =

      (mem_address[IO_PORTA_IN_bit   ] ?  porta_in                                 : 32'd0) |
      (mem_address[IO_PORTA_OUT_bit  ] ?  porta_out                                : 32'd0) |
      (mem_address[IO_PORTA_DIR_bit  ] ?  porta_dir                                : 32'd0) |
      (mem_address[IO_LEDS_bit       ] ?  LEDs                                     : 32'd0) |

      (mem_address[IO_PORTB_IN_bit   ] ?  portb_in                                 : 32'd0) |
      (mem_address[IO_PORTB_OUT_bit  ] ?  portb_out                                : 32'd0) |
      (mem_address[IO_PORTB_DIR_bit  ] ?  portb_dir                                : 32'd0) |
      (mem_address[IO_BUTTONS_IN_bit ] ?  buttons_in                               : 32'd0) |

      (mem_address[IO_OLED_IN_bit    ] ?  oled_in                                  : 32'd0) |
      (mem_address[IO_OLED_OUT_bit   ] ?  oled_out                                 : 32'd0) |
      (mem_address[IO_OLED_DIR_bit   ] ?  oled_dir                                 : 32'd0) |
      (mem_address[IO_ANALOG_OUT_bit ] ?  analog_out                               : 32'd0) |

      (mem_address[IO_UART_DAT_bit   ] |
       mem_address[IO_UART_CNTL_bit  ] ? {serial_busy, serial_valid, serial_data}  : 32'd0) |
      (mem_address[IO_Ticks_bit      ] ?  ticks                                    : 32'd0) |
      (mem_address[IO_Reload_bit     ] ?  reload                                   : 32'd0) |

      (mem_address[IO_USB_DAT_bit    ] |
       mem_address[IO_USB_CNTL_bit   ] ? {usb_configured, ~usb_ready, usb_valid, usb_data} : 32'd0) |

      (mem_address[IO_ADC_IN_bit     ] ?  adc_in                                   : 32'd0) |
      (mem_address[IO_ADC_OUT_bit    ] ?  adc_out                                  : 32'd0) |
      (mem_address[IO_SD_IN_bit      ] ?  sd_in                                    : 32'd0) |
      (mem_address[IO_SD_OUT_bit     ] ?  sd_out                                   : 32'd0) ;

   wire [31:0] io_modifier = (mem_address[3:2] == 2'b01)    ? ~mem_wdata & io_rdata :  // Clear
                             (mem_address[3:2] == 2'b10)    ?  mem_wdata | io_rdata :  // Set
                             (mem_address[3:2] == 2'b11)    ?  mem_wdata ^ io_rdata :  // Toggle
                          /* (mem_address[3:2] == 2'b00) */    mem_wdata            ;

   always @(posedge clk)
   begin

     // Variable width access, allows to control the individual bytes
     if (mem_address_is_io & mem_address[IO_PORTA_OUT_bit] & mem_wmask[0]) porta_out[ 7:0 ] <= io_modifier[ 7:0 ];
     if (mem_address_is_io & mem_address[IO_PORTA_OUT_bit] & mem_wmask[1]) porta_out[15:8 ] <= io_modifier[15:8 ];
     if (mem_address_is_io & mem_address[IO_PORTA_OUT_bit] & mem_wmask[2]) porta_out[23:16] <= io_modifier[23:16];
     if (mem_address_is_io & mem_address[IO_PORTA_OUT_bit] & mem_wmask[3]) porta_out[31:24] <= io_modifier[31:24];

     if (mem_address_is_io & mem_address[IO_PORTA_DIR_bit] & mem_wmask[0]) porta_dir[ 7:0 ] <= io_modifier[ 7:0 ];
     if (mem_address_is_io & mem_address[IO_PORTA_DIR_bit] & mem_wmask[1]) porta_dir[15:8 ] <= io_modifier[15:8 ];
     if (mem_address_is_io & mem_address[IO_PORTA_DIR_bit] & mem_wmask[2]) porta_dir[23:16] <= io_modifier[23:16];
     if (mem_address_is_io & mem_address[IO_PORTA_DIR_bit] & mem_wmask[3]) porta_dir[31:24] <= io_modifier[31:24];

     if (mem_address_is_io & mem_address[IO_PORTB_OUT_bit] & mem_wmask[0]) portb_out[ 7:0 ] <= io_modifier[ 7:0 ];
     if (mem_address_is_io & mem_address[IO_PORTB_OUT_bit] & mem_wmask[1]) portb_out[15:8 ] <= io_modifier[15:8 ];
     if (mem_address_is_io & mem_address[IO_PORTB_OUT_bit] & mem_wmask[2]) portb_out[23:16] <= io_modifier[23:16];
     if (mem_address_is_io & mem_address[IO_PORTB_OUT_bit] & mem_wmask[3]) portb_out[31:24] <= io_modifier[31:24];

     if (mem_address_is_io & mem_address[IO_PORTB_DIR_bit] & mem_wmask[0]) portb_dir[ 7:0 ] <= io_modifier[ 7:0 ];
     if (mem_address_is_io & mem_address[IO_PORTB_DIR_bit] & mem_wmask[1]) portb_dir[15:8 ] <= io_modifier[15:8 ];
     if (mem_address_is_io & mem_address[IO_PORTB_DIR_bit] & mem_wmask[2]) portb_dir[23:16] <= io_modifier[23:16];
     if (mem_address_is_io & mem_address[IO_PORTB_DIR_bit] & mem_wmask[3]) portb_dir[31:24] <= io_modifier[31:24];

     if (io_wstrb & mem_address[IO_ADC_OUT_bit   ]) adc_out    <= io_modifier;
     if (io_wstrb & mem_address[IO_OLED_OUT_bit  ]) oled_out   <= io_modifier;
     if (io_wstrb & mem_address[IO_OLED_DIR_bit  ]) oled_dir   <= io_modifier;
     if (io_wstrb & mem_address[IO_SD_OUT_bit    ]) sd_out     <= io_modifier;
     if (io_wstrb & mem_address[IO_ANALOG_OUT_bit]) analog_out <= io_modifier;
     if (io_wstrb & mem_address[IO_LEDS_bit      ]) LEDs     <= io_modifier;

   end

   // The processor reads the contents one clock cycle after the read strobe has been active.
   // Buffering it for getting IO register contents of the read strobe cycle.

   reg  [31:0] io_rdata_buffered;

   always @(posedge clk)
      if (mem_address_is_io & io_rstrb) io_rdata_buffered <= io_rdata;

   /***************************************************************************/
   // The memory bus.
   /***************************************************************************/

   // Memory map:
   //   mem_address[31:30] 00: RAM              (starts at 0x00000000)
   //                      01: IO page (1-hot)  (starts at 0x40000000)
   //                      10: SPI Flash page   (starts at 0x80000000)
   //                      11: SDRAM, 64 MB     (starts at 0xC0000000)

   wire [31:0] mem_address; // 32 bits are used internally. The two LSBs are ignored (using word addresses)
   wire  [3:0] mem_wmask;   // mem write mask and strobe /write Legal values are 0000,0001,0010,0100,1000,0011,1100,1111
   wire [31:0] mem_rdata;   // processor <- (mem and peripherals)
   wire [31:0] mem_wdata;   // processor -> (mem and peripherals)
   wire        mem_rstrb;   // mem read strobe. Goes high to initiate memory read.
   wire        mem_rbusy;   // processor <- (mem and peripherals). Stays high until a read transfer is finished.
   wire        mem_wbusy;   // processor <- (mem and peripherals). Stays high until a write transfer is finished.

   /***************************************************************************/
   // The processor.
   /***************************************************************************/

   FemtoRV32 #(
     .RESET_ADDR(32'h80200000), // Start 2 MB into SPI flash memory
     .ADDR_WIDTH(32)
   ) processor (
     .clk(clk),
     .mem_addr(mem_address),
     .mem_wdata(mem_wdata),
     .mem_wmask(mem_wmask),
     .mem_rdata(mem_rdata),
     .mem_rstrb(mem_rstrb),
     .mem_rbusy(mem_rbusy),
     .mem_wbusy(mem_wbusy),
     .interrupt_request(interrupt),
     .reset(resetq)
   );

   /***************************************************************************/
   // Memory and register access control wires.
   /***************************************************************************/

   wire mem_wstrb = |mem_wmask; // mem write strobe, goes high to initiate memory write (deduced from wmask)

   // RAM, IO or Flash ?

   wire mem_address_is_ram       = (mem_address[31:28] == 4'b0000); // 0
   wire mem_address_is_io        = (mem_address[31:28] == 4'b0100); // 4
   wire mem_address_is_char      = (mem_address[31:28] == 4'b0110); // 6
   wire mem_address_is_spi_flash = (mem_address[31:28] == 4'b1000); // 8
   wire mem_address_is_sdram     = (mem_address[31:28] == 4'b1100); // C

   wire io_rstrb = mem_rstrb & mem_address_is_io;
   wire io_wstrb = mem_wstrb & mem_address_is_io;

   /***************************************************************************/
   // 64 MB SD-RAM.
   /***************************************************************************/

   wire [31:0] sdram_rdata;
   wire sdram_busy;

   muchtoremember sdram(
     // Physical interface
    .sd_d(sdram_d),
    .sd_addr(sdram_a),
    .sd_dqm(sdram_dqm),
    .sd_cs(sdram_csn),
    .sd_ba(sdram_ba),
    .sd_we(sdram_wen),
    .sd_ras(sdram_rasn),
    .sd_cas(sdram_casn),
    .sd_clk(sdram_clk),
    .sd_cke(sdram_cke),

     // Internal bus interface
    .clk(clk),
    .resetn(resetq),
    .addr(mem_address[25:0]),
    .wmask({4{mem_address_is_sdram}} & mem_wmask),
    .rd   (   mem_address_is_sdram   & mem_rstrb),
    .din(mem_wdata),
    .dout(sdram_rdata),
    .busy(sdram_busy)
  );

   /***************************************************************************/
   // XIP from SPI flash.
   /***************************************************************************/

   // A special macro is necessary to access the clock wire of the SPI flash memory chip

   wire flash_clk;
   wire untristate = 0;
   USRMCLK mclk (.USRMCLKTS(untristate), .USRMCLKI(flash_clk));

   assign flash_wpn   = 1;
   assign flash_holdn = 1;

   wire mapped_spi_flash_rbusy;
   wire [31:0] mapped_spi_flash_rdata;

   MappedSPIFlash #( .DUMMY_CYCLES(4) ) mapped_spi_flash (
      .clk(clk),
      .rstrb(mem_rstrb && mem_address_is_spi_flash),
      .word_address(mem_address[23:2]),
      .rdata(mapped_spi_flash_rdata),
      .rbusy(mapped_spi_flash_rbusy),

      .CLK(flash_clk),
      .CS_N(flash_csn),
      .IO({flash_miso, flash_mosi})
   );

   assign  mem_rbusy = sdram_busy | mapped_spi_flash_rbusy | (mem_address_is_char & char_rbusy);
   assign  mem_wbusy = sdram_busy;

   /***************************************************************************/
   // RAM.
   /***************************************************************************/

   reg  [31:0] RAM[(128*1024/4)-1:0];
   reg  [31:0] ram_rdata;

   always @(posedge clk) begin

     if(mem_wmask[0] & mem_address_is_ram) RAM[mem_address[16:2]][ 7:0 ] <= mem_wdata[ 7:0 ];
     if(mem_wmask[1] & mem_address_is_ram) RAM[mem_address[16:2]][15:8 ] <= mem_wdata[15:8 ];
     if(mem_wmask[2] & mem_address_is_ram) RAM[mem_address[16:2]][23:16] <= mem_wdata[23:16];
     if(mem_wmask[3] & mem_address_is_ram) RAM[mem_address[16:2]][31:24] <= mem_wdata[31:24];

      ram_rdata <= RAM[mem_address[16:2]];
   end

   /***************************************************************************/
   // Connect the read wires of memories and IO registers to the memory bus.
   /***************************************************************************/

   assign mem_rdata =

      (mem_address_is_ram       ? ram_rdata              : 32'd0) |
      (mem_address_is_io        ? io_rdata_buffered      : 32'd0) |
      (mem_address_is_char      ? char_rdata             : 32'd0) |
      (mem_address_is_spi_flash ? mapped_spi_flash_rdata : 32'd0) |
      (mem_address_is_sdram     ? sdram_rdata            : 32'd0) ;

   /***************************************************************************/
   // Video mode constants and clocks
   /***************************************************************************/

   // The video signal generator is based on HDMI experiments by Bruno Levy:
   // https://github.com/BrunoLevy/learn-fpga/tree/master/Basic/ULX3S/ULX3S_hdmi

   wire pixclk;        // Pixel clock
   wire pixclk_locked; // Pixel clock locked signal
   wire half_clk_TMDS; // TMDS clock at half freq (5*pixclk)

   // Select mode by uncommenting one of the lines below
   // Note UART frequency divider and USB app clock frequency also needs to be changed.

   `define MODE_800x600_40MHz
// `define MODE_800x600_50MHz


`ifdef MODE_800x600_40MHz // SVGA 800x600 @ 60 Hz
   // localparam GFX_pixel_clock   = 40;
   localparam GFX_width         = 800;
   localparam GFX_height        = 600;
   localparam GFX_h_front_porch = 40;
   localparam GFX_h_sync_width  = 128;
   localparam GFX_h_back_porch  = 88;
   localparam GFX_v_front_porch = 1;
   localparam GFX_v_sync_width  = 4;
   localparam GFX_v_back_porch  = 23;

  // Parameters of the PLL, found using: ecppll -i 25 -o 200 -f foobar.v
   localparam CLKI_DIV = 1;
   localparam CLKOP_DIV = 3;
   localparam CLKOP_CPHASE = 1;
   localparam CLKOP_FPHASE = 0;
   localparam CLKFB_DIV = 8;
`endif

`ifdef MODE_800x600_50MHz // VESA 800x600 @ 72 Hz
   // localparam GFX_pixel_clock   = 50;
   localparam GFX_width         = 800;
   localparam GFX_height        = 600;
   localparam GFX_h_front_porch = 56;
   localparam GFX_h_sync_width  = 120;
   localparam GFX_h_back_porch  = 64;
   localparam GFX_v_front_porch = 37;
   localparam GFX_v_sync_width  = 6;
   localparam GFX_v_back_porch  = 23;

  // Parameters of the PLL, found using: ecppll -i 25 -o 250 -f foobar.v
   localparam CLKI_DIV = 1;
   localparam CLKOP_DIV = 2;
   localparam CLKOP_CPHASE = 0;
   localparam CLKOP_FPHASE = 0;
   localparam CLKFB_DIV = 10;
`endif

   /***************************************************************************/
   // The PLL
   /***************************************************************************/

   // The PLL converts a 25 MHz clock into a (pixel_clock_freq * 5) clock
   // The TMDS serializers operate at (pixel_clock_freq * 10), but we use
   // DDR mode, hence (pixel_clock_freq * 5).
   // The (half) TMDS serializer clock is generated on pin CLKOP.
   // In addition, the pixel clock (at TMDS freq/5) is generated on
   // pin CLKOS (hence CLKOS_DIV = 5*CLKOP_DIV).

   (* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
    EHXPLLL #(
        .CLKI_DIV(CLKI_DIV),
        .CLKOP_DIV(CLKOP_DIV),
        .CLKOP_CPHASE(CLKOP_CPHASE),
        .CLKOP_FPHASE(CLKOP_FPHASE),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(5*CLKOP_DIV),
        .CLKOS_CPHASE(CLKOP_CPHASE),
        .CLKOS_FPHASE(CLKOP_FPHASE),
        .CLKFB_DIV(CLKFB_DIV)
    ) pll_i (
        .CLKI(clk_25mhz),
        .CLKOP(half_clk_TMDS),
        .CLKFB(half_clk_TMDS),
        .CLKOS(pixclk),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(pixclk_locked)
     );

   /***************************************************************************/
   // X, Y, hSync, vSync, DrawArea
   /***************************************************************************/

   localparam GFX_line_width = GFX_width  + GFX_h_front_porch + GFX_h_sync_width + GFX_h_back_porch;
   localparam GFX_lines      = GFX_height + GFX_v_front_porch + GFX_v_sync_width + GFX_v_back_porch;

   reg [10:0] GFX_X, GFX_Y;
   reg hSync, vSync, DrawArea;

   always @(posedge pixclk) DrawArea <= (GFX_X<GFX_width) && (GFX_Y<GFX_height);

   always @(posedge pixclk) GFX_X <= (GFX_X==GFX_line_width-1) ? 0 : GFX_X+1;
   always @(posedge pixclk) if(GFX_X==GFX_line_width-1) GFX_Y <= (GFX_Y==GFX_lines-1) ? 0 : GFX_Y+1;

   always @(posedge pixclk) hSync <=
      (GFX_X>=GFX_width+GFX_h_front_porch) && (GFX_X<GFX_width+GFX_h_front_porch+GFX_h_sync_width);

   always @(posedge pixclk) vSync <=
      (GFX_Y>=GFX_height+GFX_v_front_porch) && (GFX_Y<GFX_height+GFX_v_front_porch+GFX_v_sync_width);

   /***************************************************************************/
   // Text mode with 8x16 bitmap font
   /***************************************************************************/

   wire [10:0] xpos = GFX_X;
   wire [ 9:0] ypos = GFX_Y;
   wire vga_enable = DrawArea;
   wire hsync = hSync;
   wire vsync = vSync;

   reg [7:0] red, green, blue;

   reg  hsync_d1,  hsync_d2,  hsync_d3;
   reg  vsync_d1,  vsync_d2,  vsync_d3;
   reg enable_d1, enable_d2, enable_d3;

   always @(posedge clk)
   begin
     // The pixel pipeline needs three clock cycles to provide bitmap data after
     // the coordinates are valid, but the sync signals arrive the same cycle as the coordinates.
     // Delay the timing signals for three cycles to get both in sync.

     hsync_d1 <= hsync;
     hsync_d2 <= hsync_d1;
     hsync_d3 <= hsync_d2;

     vsync_d1 <= vsync;
     vsync_d2 <= vsync_d1;
     vsync_d3 <= vsync_d2;

     enable_d1 <= vga_enable;
     enable_d2 <= enable_d1;
     enable_d3 <= enable_d2;
                                      // Black (required by VGA during blanking)
     {red, green, blue}  <= ~enable_d2 ? 24'b00000000_00000000_00000000 :
                                      // Cyan (highlight)                  Orange (normal)                  Navy background
         bitmap_shift[7] ? colorswitch ? 24'b00000000_11100000_11100000 :  24'b11100000_10100000_00000000 : 24'b00000000_00000000_01100000;
   end

   // Combined memory for characters and font data
   reg [7:0] characters [3*512 + 4095:0]; initial $readmemh("font-vga.hex", characters, 4096);

   reg [7:0] char, bitmap_shift;
   reg colorswitch, colorswitch_delay;

   wire [12:0] characterindex = xpos[2:0] == 3'b000 ? xpos[9:3] + 100 * ypos[9:4] :
                                xpos[2:0] == 3'b001 ? {char[6:0], ypos[3:0]}  + (13'd4096 - 13'd32*16) :
                                mem_address[12:0];
   reg char_rbusy;

   wire remove = ypos[9:4] == 6'd37; // Do not display line 38 as this is cut in half

   always @(posedge clk) // Pixel pipeline.
   begin
      // First & second cycle:
      char    <= characters[ characterindex ]; // First cycle: 7-Bit ASCII. Using char[7] for highlight color.
                                              // Second cycle: 8x16 pixel font bitmap data.
      char_rbusy <= xpos[2:1] == 2'b00;

      // Second cycle:
      colorswitch_delay <= char[7];

      // Third cycle:
      if (xpos[2:0] == 3'b010) begin if (~remove) bitmap_shift <= char; colorswitch <= colorswitch_delay; end
      else                     begin bitmap_shift <= {bitmap_shift[6:0], 1'b0}; end
   end

   // This is a little trick to coax a word-addressed CPU into byte aligned reads and writes:

   wire [31:0] char_rdata = {char, char, char, char};

   always @(posedge clk)
     if(mem_wstrb & mem_address_is_char) characters[mem_address[12:0]] <= mem_wdata[7:0];

   /***************************************************************************/
   // RGB TMDS encoding
   /***************************************************************************/

   // Generate 10-bits TMDS red,green,blue signals.
   // Blue embeds HSync/VSync in its control part.

   wire [9:0] TMDS_red, TMDS_green, TMDS_blue;

   TMDS_encoder encode_R(.clk(pixclk), .VD(red  ), .CD(2'b00),               .VDE(enable_d3), .TMDS(TMDS_red));
   TMDS_encoder encode_G(.clk(pixclk), .VD(green), .CD(2'b00),               .VDE(enable_d3), .TMDS(TMDS_green));
   TMDS_encoder encode_B(.clk(pixclk), .VD(blue ), .CD({vsync_d3,hsync_d3}), .VDE(enable_d3), .TMDS(TMDS_blue));

   /***************************************************************************/
   // Shifter
   /***************************************************************************/

   // Serialize the three 10-bits TMDS red, green, blue signals.
   // This version of the shifter shifts and sends two bits per clock,
   // using the ODDRX1F block of the ULX3S.

   // The counter counts modulo 5 instead of modulo 10 (because we shift two
   // bits at each clock)
   reg [4:0] TMDS_mod5=1;
   always @(posedge half_clk_TMDS) TMDS_mod5 <= {TMDS_mod5[3:0],TMDS_mod5[4]};
   wire TMDS_shift_load = TMDS_mod5[4];

   // Shifter now shifts two bits at each clock
   reg [9:0] TMDS_shift_red=0, TMDS_shift_green=0, TMDS_shift_blue=0;
   always @(posedge half_clk_TMDS) begin
      TMDS_shift_red   <= TMDS_shift_load ? TMDS_red   : TMDS_shift_red  [9:2];
      TMDS_shift_green <= TMDS_shift_load ? TMDS_green : TMDS_shift_green[9:2];
      TMDS_shift_blue  <= TMDS_shift_load ? TMDS_blue  : TMDS_shift_blue [9:2];
   end

   // DDR serializers: they send D0 at the rising edge and D1 at the falling edge.
   ODDRX1F ddr_red  (.D0(TMDS_shift_red[0]),   .D1(TMDS_shift_red[1]),   .Q(gpdi_dp[2]), .SCLK(half_clk_TMDS), .RST(1'b0));
   ODDRX1F ddr_green(.D0(TMDS_shift_green[0]), .D1(TMDS_shift_green[1]), .Q(gpdi_dp[1]), .SCLK(half_clk_TMDS), .RST(1'b0));
   ODDRX1F ddr_blue (.D0(TMDS_shift_blue[0]),  .D1(TMDS_shift_blue[1]),  .Q(gpdi_dp[0]), .SCLK(half_clk_TMDS), .RST(1'b0));

   // The pixel clock is sent through the fourth differential pair.
   assign gpdi_dp[3] = pixclk;

   // Note (again): gpdi_dn[3:0] is generated automatically by LVCMOS33D mode in ulx3s_v20.lpf
endmodule


// 40 MHz system clock
// ecppll -i 25 -o 40 -f /dev/stdout

module pll40
(
    input clkin, // 25 MHz, 0 deg
    output clkout0, // 40 MHz, 0 deg
    output locked
);
(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="40" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(5),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(15),
        .CLKOP_CPHASE(7),
        .CLKOP_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(8)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clkin),
        .CLKOP(clkout0),
        .CLKFB(clkout0),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(locked)
        );
endmodule


// 48 MHz clock for USB
// ecppll -i 25 -o 48 --highres -f /dev/stdout

module pll48
(
    input clkin, // 25 MHz, 0 deg
    output clkout0, // 48 MHz, 0 deg
    output locked
);
wire clkfb;
(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOS="48" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(5),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(48),
        .CLKOP_CPHASE(9),
        .CLKOP_FPHASE(0),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(10),
        .CLKOS_CPHASE(0),
        .CLKOS_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(2)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clkin),
        .CLKOP(clkfb),
        .CLKOS(clkout0),
        .CLKFB(clkfb),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(locked)
        );
endmodule
