from PIL import Image
import numpy as np

def merge_images_vertically_with_top_spacer(images_paths, spacer_height):
    # Load the first image to determine the width and total height for the new image
    first_image = Image.open(images_paths[0])
    total_width = first_image.width
    # Adjust total height to include an additional spacer at the top
    total_height = sum(Image.open(path).height for path in images_paths) + spacer_height * (len(images_paths) + 1)

    # Create a new image with the calculated dimensions
    merged_image = Image.new('RGBA', (total_width, total_height), (0, 0, 0, 0))

    # Initialize the current height position for pasting images, starting from spacer_height to include top spacer
    current_height = spacer_height
    for path in images_paths:
        image = Image.open(path)
        merged_image.paste(image, (0, current_height))
        current_height += image.height + spacer_height  # Move the position and add a spacer after each image

    return merged_image

# Paths to the images generated previously
images_paths = [f'yellow_fire_{i+1}.png' for i in range(20)]  # Ensure these paths are correct
spacer_height = 0  # Height of the transparent spacer in pixels, including top spacer

# Merge the images with a top spacer and save the result
merged_image_with_top_spacer = merge_images_vertically_with_top_spacer(images_paths, spacer_height)
merged_image_path_with_top_spacer = 'merged_yellow_fire.png'  # Adjust path as needed
merged_image_with_top_spacer.save(merged_image_path_with_top_spacer)

print(f"Merged image saved to: {merged_image_path_with_top_spacer}")
