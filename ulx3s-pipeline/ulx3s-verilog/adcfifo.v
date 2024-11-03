

`default_nettype none

module adcfifo (
   input clk,
   input resetq,

   input  wr,
   input  rd,
   input  [15:0] store_data,
   output [15:0] fetch_data,

   output valid
);

  reg [15:0] messwerte [7:0]; // 8 Elemente Platz im Ringpuffer
  reg [2:0] lesezeiger;
  reg [2:0] schreibzeiger;

  assign fetch_data = messwerte[lesezeiger];
  assign valid = ~(lesezeiger == schreibzeiger);

  always @(posedge clk)
  if (~resetq)
  begin
    lesezeiger <= 0;
    schreibzeiger <= 0;
  end
  else
  begin

    if (wr)
    begin
      messwerte[schreibzeiger] <= store_data;
      schreibzeiger <= schreibzeiger + 1;
    end

    if (rd) lesezeiger <= lesezeiger + 1;
  end

endmodule
