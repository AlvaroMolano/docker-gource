#!/bin/bash
set -e # stop on first error

rm -f /results/{gource.ppm,gource.mp4}
RES="${RES:-1280x720}"
DEPTH="${DEPTH:-24}"

screen -dmS recording xvfb-run -a -s "-screen 0 ${RES}x${DEPTH}" gource "-$RES" -r 30 --title "$TITLE" --user-image-dir /avatars/ --highlight-all-users -s 0.5 --seconds-per-day ${SEC_PER_DAY:-1} --hide filenames -o /results/gource.ppm

# This hack is needed because gource process doesn't stop
lastsize="0"
filesize="0"
while [[ "$filesize" -eq "0" || $lastsize -lt $filesize ]] ;
do
    sleep 20
    lastsize="$filesize"
    filesize=$(stat -c '%s' /results/gource.ppm)
    echo 'Polling the size. Current size is' $filesize
done
echo 'Force stopping recording because file size is not growing'
screen -S recording -X quit

xvfb-run -a -s "-screen 0 ${RES}x${DEPTH}" ffmpeg -y -r 30 -f image2pipe -loglevel info -vcodec ppm -i /results/gource.ppm -vcodec libx264 -preset medium -pix_fmt yuv420p -crf 1 -threads 0 -bf 0 /results/gource.mp4
rm -f /results/gource.ppm

