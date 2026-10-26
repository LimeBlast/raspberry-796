#!/bin/sh
# Make an invisible cursor theme, "blank": one transparent pixel for every pointer shape.
mkdir -p ~/.icons/blank/cursors && cd ~/.icons/blank/cursors
python3 -c '
import struct
# Xcursor file: one 1x1 fully transparent image at nominal size 24
img = struct.pack("<9I", 36, 0xfffd0002, 24, 1, 1, 1, 0, 0, 0) + struct.pack("<I", 0)
hdr = b"Xcur" + struct.pack("<3I", 16, 0x10000, 1) + struct.pack("<3I", 0xfffd0002, 24, 28)
open("default", "wb").write(hdr + img)
'
for n in $(ls /usr/share/icons/Adwaita/cursors); do [ "$n" = default ] || ln -sf default "$n"; done
printf "[Icon Theme]\nName=blank\n" > ../index.theme
