#! /bin/bash

function background
{

qrcode_file_png=$(dirname "$0")/../toxid.png
qrcode_file_rgba=$(dirname "$0")/../toxid.rgba
qrcode_touchfile_ready=$(dirname "$0")/../toxid_ready.txt
toxidstr="$1"

. $(dirname "$0")/vars.sh

# also put toxid.txt file into "db" dir
cp $(dirname "$0")/../toxid.txt $(dirname "$0")/../db/toxid.txt

rm -f "$qrcode_file_png"
rm -f "aa""$$"".png"
qrencode -t PNG -o "$qrcode_file_png" "$toxidstr"

if [ "$RASPI5_FB""x" == "0x" ]; then
    convert "$qrcode_file_png" -scale "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" "aa""$$"".png"
    rm -f "$qrcode_file_rgba"
    convert "aa""$$"".png" -gravity northwest -background black -extent "${real_width}x${FB_HEIGHT}" "$qrcode_file_rgba"
    rm -f "aa""$$"".png"
elif [ "$RASPI5_FB""x" == "2x" ]; then
    convert "$qrcode_file_png" -scale "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" "aa""$$"".png"
    rm -f "$qrcode_file_rgba"
    convert "aa""$$"".png" -gravity northwest -background black -extent "${real_width}x${FB_HEIGHT}" "$qrcode_file_rgba"
    rm -f "aa""$$"".png"
else # RASPI5_FB == 1
    fb_bit_depth=$(fbset|grep geometry|awk '{ print $6}')
    convert "$qrcode_file_png" -scale "${BKWALL_WIDTH}x${BKWALL_HEIGHT}" "aa""$$"".png"
    rm -f "$qrcode_file_rgba"
    rm -f "$qrcode_file_rgba""2"
    convert "aa""$$"".png" -gravity northwest -background black -extent "${real_width}x${FB_HEIGHT}" "$qrcode_file_rgba""2"
    rm -f "aa""$$"".png"
    ffmpeg -y -i "$qrcode_file_rgba""2" -vcodec rawvideo -f rawvideo -pix_fmt rgb565 -s "${real_width}x${FB_HEIGHT}" "$qrcode_file_rgba" >/dev/null 2>/dev/null
    rm -f "$qrcode_file_rgba""2"
fi

touch "$qrcode_touchfile_ready"

}

background "$1" &

