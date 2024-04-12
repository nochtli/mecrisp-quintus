
# -----------------------------------------------------------------------------
#  Fading blinky for Vega Thejas32 on Aries V2
# -----------------------------------------------------------------------------

# Pins 0 to 15:

.equ GPIO0_DATA,     0x10080000
.equ GPIO0_DATA_ALL, 0x100BFFFC
.equ GPIO0_DIR,      0x100C0000

# Pins 16 to 31:

.equ GPIO1_DATA,     0x10180000
.equ GPIO1_DATA_ALL, 0x101BFFFC
.equ GPIO1_DIR,      0x101C0000

# Direction is selects 0: Input, 1: Output.
# Data bits are masked using 16 address bits, shifted two places,
# which are ORed to the base address.

# Active low RGB LED is connected to GPIO pins 22, 23 and 24.

# ------------------------------------------------------------------------------
#  Execution starts here
# ------------------------------------------------------------------------------

.text

Reset:

  li x8,  GPIO1_DATA | ( ( (1<<8) | ( 1<<7) | (1<<6) ) << 2) # Mask for GPIO pins 22, 23 and 24
  li x15, -1                                                 # RGB LED is active low --> off
  sw x15, 0(x8)

  li x14, GPIO1_DIR                                          # Set GPIO pins 22, 23 and 24 as outputs
  li x15, (1<<8) | ( 1<<7) | (1<<6)
  sw x15, 0(x14)

  # Initialisation of GPIO done.

  li   x10, 1                    # Set up initial x, y for Minsky circle algorithm
  slli x11, x10, 19

# -----------------------------------------------------------------------------
breathe_led: # Generate smooth breathing LED effect
# -----------------------------------------------------------------------------

    # Register usage:

    # x8  : Initialised with IO address for GPIO
    # x9  : Phase accumulator for sigma-delta modulator
    # x10 : Minsky circle algorithm x = sin(t)
    # x11 : Minsky circle algorithm y = cos(t)
    # x12 : Suitably scaled cos(t)
    # x13 : Approximated exp(cos(t))
    # x14 : Output for LED

                                 # Minsky circle algorithm x, y = sin(t), cos(t)
    srai x12, x10, 17            # -dx = y >> 17
    sub  x11, x11, x12           #  x += dx
    srai x12, x11, 17            #  dy = x >> 17
    add  x10, x10, x12           #  y += dy

    srai x12, x11, 14            # -24 <= x12 <= 32   --> scaled cos(t)
    addi x12, x12, 180           # 156 <= x12 <= 212  --> scaled cos(t) with offset

    andi x13, x12, 7             # Simplified bitexp function.
    addi x13, x13, 8             #   Valid for inputs up to 231
    srli x12, x12, 3             #   Gives too small values above 231
    sll  x13, x13, x12           # Input in x12, output in x13

   # Slow down updating a bit by using current brightness multiple times
   li x15, 85                    # <-- You can change this value, no magic here
1: addi x15, x15, -1

    add  x9, x9, x13             # Sigma-Delta phase accumulator
    sltu x14, x9, x13            # Sigma-Delta output on overflow
    addi x14, x14, -1            # (0, 1) --> (-1, 0) # For active low  LEDs
#   sub  x14, zero, x14          # (0, 1) --> (0, -1) # For active high LEDs
    sw x14, 0(x8)                # Set all LEDs at once

   bne x15, zero, 1b

   j breathe_led
