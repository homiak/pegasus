from PIL import Image
import numpy as np
import random

def create_image_with_varied_transparency(image_path, output_size, max_transparency_height):
    """
    Creates an image of the specified size with varied column heights and transparency at the top.
    
    Args:
    image_path (str): Path to the original image.
    output_size (tuple): Desired output size (width, height) of the image.
    max_transparency_height (int): Maximum height of transparency from the top.
    
    Returns:
    Image: The generated image with varied transparency.
    """
    # Load the original image
    original_img = Image.open(image_path)
    original_data = np.array(original_img)

    # Get all unique colors in the image, excluding fully transparent ones
    unique_colors = np.unique(original_data.reshape(-1, 4), axis=0)
    non_grey_colors = unique_colors[(unique_colors[:,0] != unique_colors[:,1]) | (unique_colors[:,2] != unique_colors[:,1])]

    # Sort the non-grey colors by the sum of their RGB values (intensity)
    non_grey_colors_sorted = non_grey_colors[np.argsort(np.sum(non_grey_colors[:, :3], axis=1))][::-1]

    # Initialize the new image array with transparency
    new_image_data = np.zeros((output_size[0], output_size[1], 4), dtype=np.uint8)
    new_image_data[:, :, 3] = 0  # Set alpha channel to 0 (fully transparent)

    # Assign colors to each column with varying heights
    for x in range(output_size[1]):
        # Random height for colored pixels in this column
        height = random.randrange(max_transparency_height, output_size[0])
        
        # Assign colors from bottom to top, to keep brighter clusters towards the bottom
        for y in range(output_size[0] - 1, output_size[0] - height - 1, -1):
            color_idx = (output_size[0] - y) % len(non_grey_colors_sorted)
            new_image_data[y, x, :] = non_grey_colors_sorted[color_idx]

    # Create and return the new Image object
    new_image = Image.fromarray(new_image_data, 'RGBA')
    return new_image

# Parameters
original_image_path = 'yellow_fire.png'
output_size = (32, 32)  # Output size (width, height)
max_transparency_height = int(output_size[0] * 0.25)  # Max height of transparency from the top

# Create the new image with transparency at the top and varied column heights
new_image_with_transparency = create_image_with_varied_transparency(original_image_path, output_size, max_transparency_height)

# Save the new image
new_image_path_with_transparency = 'yellow_fire_gen.png'
new_image_with_transparency.save(new_image_path_with_transparency, 'PNG')



