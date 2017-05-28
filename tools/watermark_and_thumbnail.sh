#!/bin/bash
set -x

echo "ImageMagick must be installed"

generate_thumb() {
  image="$1"
  path=$(dirname "$image")
  filename=$(basename "$image")
  extension="${filename##*.}"
  filename="${filename%.*}"
  convert "$image" -auto-orient \
          -thumbnail 1200x800 "$path/$filename-thumb.$extension"
}

watermark() {
  image="$1"
  convert -size 500x100 xc:grey30 -font Arial -pointsize 25 -gravity center \
          -draw "fill grey70  text 0,0  '(c) Marc Khouri <marc@khouri.ca>'" \
          stamp_fgnd.png
  convert -size 500x100 xc:black -font Arial -pointsize 25 -gravity center \
          -draw "fill white  text  1,1  '(c) Marc Khouri <marc@khouri.ca>'  \
                             text  0,0  '(c) Marc Khouri <marc@khouri.ca>'  \
                 fill black  text -1,-1 '(c) Marc Khouri <marc@khouri.ca>'" \
          +matte stamp_mask.png
  composite -compose CopyOpacity stamp_mask.png stamp_fgnd.png stamp.png
  mogrify -trim +repage stamp.png

  composite -gravity south -geometry +0+10 stamp.png "$image" \
            wmark_text_stamped.jpg
}

easy_watermark() {
  image="$1"
  path=$(dirname "$image")
  filename=$(basename "$image")
  extension="${filename##*.}"
  filename="${filename%.*}"
  convert "$image" -font Arial -pointsize 50 \
        -draw "gravity south-east \
               fill black  text 0,12 '(c) Marc Khouri <marc@khouri.ca>' \
               fill white  text 1,11 '(c) Marc Khouri <marc@khouri.ca>' " \
        "$image"
}

for pic in "$@"; do
  easy_watermark "$pic"
  generate_thumb "$pic"
done
