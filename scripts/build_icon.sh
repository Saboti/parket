#!/bin/sh

set -eu
PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

if [ "$#" -ne 2 ]; then
    echo "usage: $0 SOURCE_PNG OUTPUT_ICNS" >&2
    exit 1
fi

source_png="$1"
output_icns="$2"
iconset_dir=".build/AppIcon.iconset"
square_png=".build/AppIcon-square.png"

/bin/mkdir -p .build
/bin/rm -rf "$iconset_dir"
/bin/mkdir -p "$iconset_dir"

width=$(/usr/bin/sips -g pixelWidth "$source_png" | /usr/bin/awk '/pixelWidth/ { print $2 }')
height=$(/usr/bin/sips -g pixelHeight "$source_png" | /usr/bin/awk '/pixelHeight/ { print $2 }')

if [ "$width" -le "$height" ]; then
    crop_size="$width"
else
    crop_size="$height"
fi

/usr/bin/sips --cropToHeightWidth "$crop_size" "$crop_size" "$source_png" --out "$square_png" >/dev/null

/usr/bin/sips -z 16 16 "$square_png" --out "$iconset_dir/icon_16x16.png" >/dev/null
/usr/bin/sips -z 32 32 "$square_png" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
/usr/bin/sips -z 32 32 "$square_png" --out "$iconset_dir/icon_32x32.png" >/dev/null
/usr/bin/sips -z 64 64 "$square_png" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
/usr/bin/sips -z 128 128 "$square_png" --out "$iconset_dir/icon_128x128.png" >/dev/null
/usr/bin/sips -z 256 256 "$square_png" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
/usr/bin/sips -z 256 256 "$square_png" --out "$iconset_dir/icon_256x256.png" >/dev/null
/usr/bin/sips -z 512 512 "$square_png" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
/usr/bin/sips -z 512 512 "$square_png" --out "$iconset_dir/icon_512x512.png" >/dev/null
/usr/bin/sips -z 1024 1024 "$square_png" --out "$iconset_dir/icon_512x512@2x.png" >/dev/null

/usr/bin/iconutil -c icns "$iconset_dir" -o "$output_icns"