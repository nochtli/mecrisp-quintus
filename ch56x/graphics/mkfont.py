#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import struct
import random

def rand(n):
    return random.randrange(n)

def as565(im):
    """ Return RGB565 of im """
    (r,g,b) = [np.array(c).astype(np.uint16) for c in im.split()]
    def s(x, n):
        return x * (2 ** n - 1) // 255
    return (s(b, 5) << 11) | (s(g, 6) << 5) | s(r, 5)

def c3(rgb):
    return (16 * (0xf & (rgb >> 8)),
            16 * (0xf & (rgb >> 4)),
            16 * (0xf & (rgb >> 0)))

font1 = ImageFont.truetype("IBMPlexSans-Regular.otf", 6)
font2 = ImageFont.truetype("IBMPlexSans-SemiBold.otf", 13)

def rfont2(c):
    im = Image.new("L", (128, 160))
    dr = ImageDraw.Draw(im)
    dr.text((10,40), c, font=font2, fill=255)
    extents = im.getbbox()
    if not extents:
        return [0]
    print(str(extents))
    # assert 10 <= extents[0]
    # assert 45 <= extents[1]
    if c in "0123456789":
        extents = (0, 0, 10 + 8, 45 + 9)
    im = im.crop((10, 45) + extents[2:])
    (w,h) = im.size
    nyb = (np.array(im).astype(int).flatten() * 15 // 255).tolist()
    return [w,h] + nyb

def cwidth(c):
    return rfont2(c)[0]

fs = open("font.fs", "wt")
fb = 0

if 0:
    im = Image.new("L", (128, 160))
    dr = ImageDraw.Draw(im)
    dr.text((10,40), "0123456789ABCDEF.Vm", font=font1, fill=255)
    im = im.crop(im.getbbox())
    (w,h) = im.size
    print (w, h)
    im.save("out.png")
else:
    im = Image.new("RGB", (128, 160))
    dr = ImageDraw.Draw(im)
    # dr.text((77,0), "4.985 V", font=font2, fill=(255,255,255))
    # dr.text((77,20), "  3.3 V", font=font2, fill=(255,255,255))
    measc = (0xe0,) * 3

    # dr.text((77,0), "230 mA", font=font2, fill=measc)
    for i in range(10):
        c = 255 * i // 9
        dr.text((i * 8, 0), "L", font=font2, fill=(c,c,c))

    dr.text((77,20), "4.985 V", font=font2, fill=measc)
    for i,(l,dx,c) in enumerate((
        ("SCK",     -2, c3(0xf92)),
        ("MISO",     0, c3(0xfe2)),
        ("MOSI",     0, c3(0x8f2)),
        ("CS",       -1, (30,144,255)),
        ("A",        0, (218,112,214)),
        ("B",        0, (128,128,96)),
        )):
        (w, h) = dr.textsize(l, font=font2)
        y = 41 + 21 * i
        (y0, y1) = (y + 5, y + 13)
        lev = rand(2)
        cd = tuple([2*m//3 for m in c])
        s = 2
        for x in range(0, 90, s):
            dr.line((x - s, (y0,y1)[lev], x, (y0,y1)[lev]), fill=cd)
            if rand(6) == 0:
                dr.line((x, (y0,y1)[lev], x, (y1,y0)[lev]), fill=cd)
                lev = 1 - lev
        dr.text((112 - w/2, y), l, font=font2, fill=c)
        (r,g,b) = [v//16 for v in c]
        fb += 5 + len(l)
    fb += 5 + len("V")
    fb += 5 + len("mA")
    fb += 1
    im.save("font1.png")

def encode(font, c):
    im = Image.new("L", (128, 160))
    dr = ImageDraw.Draw(im)
    dr.text((10,40), c, font=font1, fill=255)
    # print im.getbbox()
    im = im.crop((10, 44, 16, 51))
    (w,h) = im.size
    nyb = (np.array(im).flatten() * 10 / 255).tolist()
    return nyb

print('font1 takes', sum([len(encode(font1, c)) for c in "0123456789A.Vm"]) / 2, 'bytes')

import string
uniq = "".join(sorted(set(string.printable[:-5])))
f2 = sum([rfont2(c) for c in uniq], [])
print("font2 %s takes %d bytes" % (uniq, len(f2) / 2))

im = Image.new("L", (700, 20))
dr = ImageDraw.Draw(im)
dr.text((0,0), uniq, font=font2, fill=255)
im.save("font2.png")

def nybbles(nn):
    s = len(nn)
    nn += [0]
    b = ["$%04x h, " % ((nn[i] << 1) | (nn[i] << 12) | (nn[i] << 7)) for i in range(0, s)]
    return b

# See http://angband.pl/font/tinyfont.html
fs.write("\ncreate micro\n")
tiny = Image.open("hex4x5.png").convert("L")
for i in range(16):
    x = 5 * i
    ch = ((np.array(tiny.crop((x, 0, x + 4, 5)))).flatten() * 15.99 / 255).astype(np.uint8).tolist()
    fs.write("".join(nybbles(ch)) + "\n")
    fb += len(ch) / 2

fs.write("\nalign\n")
