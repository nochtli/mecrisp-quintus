#
#    Mecrisp-Quintus - A native code Forth implementation for RISC-V
#    Copyright (C) 2018  Matthias Koch
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# -----------------------------------------------------------------------------
  Definition Flag_inline, "dflash!" # ( x 64-addr -- )
# Given a value 'x' and a cell-aligned address 'addr', stores 'x' to memory at 'addr', consuming both.
# -----------------------------------------------------------------------------
dflashstore:
  lc x15, 0(x9)
  sc x15, 0(x8)
  lc x8, CELL(x9)
  addi x9, x9, 2*CELL
  ret

# -----------------------------------------------------------------------------
  Definition Flag_inline, "wflash!" # ( x 32-addr -- )
# Given a value 'x' and a cell-aligned address 'addr', stores 'x' to memory at 'addr', consuming both.
# -----------------------------------------------------------------------------
flashstore:
  lc x15, 0(x9)
  sw x15, 0(x8)
  lc x8, CELL(x9)
  addi x9, x9, 2*CELL
  ret

# -----------------------------------------------------------------------------
  Definition Flag_inline, "hflash!" # ( x 16-addr -- )
# Given a value 'x' and a 2-aligned address 'addr', stores 'x' to memory at 'addr', consuming both.
# -----------------------------------------------------------------------------
hflashstore:
  lc x15, 0(x9)
  sh x15, 0(x8)
  lc x8, CELL(x9)
  addi x9, x9, 2*CELL
  ret
