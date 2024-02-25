from PIL import Image
import numpy as np

def merge_images_vertically_with_spacer(images_paths, spacer_height):
    # Load the first image to determine the width and total height for the new image
    first_image = Image.open(images_paths[0])
    total_width = first_image.width
    total_height = sum(Image.open(path).height for path in images_paths) + spacer_height * (len(images_paths) - 1)

    # Create a new image with the calculated dimensions
    merged_image = Image.new('RGBA', (total_width, total_height), (0, 0, 0, 0))

    # Initialize the current height position for pasting images
    current_height = 0
    for path in images_paths:
        image = Image.open(path)
        merged_image.paste(image, (0, current_height))
        current_height += image.height + spacer_height  # Move the position and add a spacer
    
    merged_image.paste(image, (0, spacer_height))
    return merged_image

# Paths to the images generated previously
images_paths = [f'yellow_fire_{i+1}.png' for i in range(10)]
spacer_height = 3  # Height of the transparent spacer in pixels

# Merge the images and save the result
merged_image = merge_images_vertically_with_spacer(images_paths, spacer_height)
merged_image_path = 'yellow_fire_amin.png'
merged_image.save(merged_image_path)

print(f"Merged image saved to: {merged_image_path}")
