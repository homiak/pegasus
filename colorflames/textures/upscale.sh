#!/bin/bash

# The target size for upscaling
target_size="32:32"

# Generate random adjustments for hue and saturation
# Hue shift (in degrees) - within +/- 10 degrees for subtlety
hue_shift=$((RANDOM % 20 - 10))
# Saturation adjustment - a factor, where 1 is unchanged, and around 0.9 to 1.1 introduces slight variations
saturation_factor=$(awk -v min=0.9 -v max=1.1 'BEGIN{srand(); print min+rand()*(max-min)}')

echo "Hue shift: $hue_shift"
echo "Saturation factor: $saturation_factor"

# Use FFmpeg to resize the image, apply color adjustments, and preserve transparency
# ffmpeg -i cyan_fire_inv.png -vf "scale=$target_size:flags=lanczos+full_chroma_inp+full_chroma_int,hue='h=$hue_shift:s=$saturation_factor':s=1" -c:a copy output.png
# ffmpeg -i cyan_fire_inv.png -vf "format=rgba,scale=32:32:flags=lanczos,hue=h=$hue_shift:s=$saturation_factor" output.png
ffmpeg -i cyan_fire_inv.png -vf "scale=32:32:flags=nearest,format=rgba" output.png
