# Mecrisp-Quintus for CH32X035 chip.

The CH32X035 is a microcontroller based on QingKe V4C RISC-V core.

This port was developed using a CH32X035C8T6-EVT-R0 evaluation board and
a WCH-LinkE debug adapter. Note that the port is experimental. I haven't
done much with it yet.

This port was derived from the CH32L103 port. Since the CH32X035 only
supports fast flash programming (256-byte blocks) and does not support
standard flash programming (2-byte writes), flash programming is not
supported by this port.

(BTW: The CH32L103 also supports standard flash programming, even though
its datasheet states that it only supports fast programming.)

## Links

CH32X035 Overview: [CH32X035.html](https://www.wch-ic.com/products/CH32X035.html)

CH32X035 Datasheet: [CH32X035DS0.PDF](https://www.wch-ic.com/downloads/CH32X035DS0_PDF.html)

CH32X035 Reference Manual: [CH32X035RM.PDF](https://www.wch-ic.com/downloads/CH32X035RM_PDF.html)

WCH-Link usage instructions: [WCH-LINK](http://www.wch-ic.com/products/WCH-Link.html)
