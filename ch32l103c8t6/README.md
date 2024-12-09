# Mecrisp-Quintus for CH32L103 chip.

The CH32L103 is a low-power general-purpose microcontroller based on QingKe
V4C RISC-V core.

This port was developed using a CH32L103C8T6-EVT-R0 evaluation board
and a WCH-LinkE debug adapter. Note that the port is experimental. I haven't
done much with it yet.

This port is almost the same as the one for the CH32V203F8P6 chip. Please read
the documentation for this port. The main difference is that the CH32L103 does
not have the weird 0xe339e339 FLASH quirk.

## Links

CH32V103 Overview: [CH32L103.html](https://www.wch-ic.com/products/CH32L103.html)

CH32V103 Datasheet: [CH32L103DS0.PDF](https://www.wch-ic.com/downloads/CH32L103DS0_PDF.html)

CH32V103 Reference Manual: [CH32L103RM.PDF](https://www.wch-ic.com/downloads/CH32L103RM_PDF.html)

WCH-Link usage instructions: [WCH-LINK](http://www.wch-ic.com/products/WCH-Link.html)
