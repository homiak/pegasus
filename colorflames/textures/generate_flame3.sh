from PIL import Image
import numpy as np
import random

def create_image_with_colored_bottom(image_path, output_size, transparency_height_fraction):
    # Load the original image and convert it to RGBA
    original_img = Image.open(image_path).convert("RGBA")
    original_data = np.array(original_img)

    # Identify and sort colors by brightness, excluding completely transparent pixels
    colors, counts = np.unique(original_data.reshape(-1, 4), axis=0, return_counts=True)
    bright_colors = colors[np.where((colors[:,3] > 0) & ((colors[:,0] > 80) | (colors[:,1] > 80) | (colors[:,2] > 80)))]
    bright_colors_sorted = bright_colors[np.argsort(np.sum(bright_colors[:, :3], axis=1))][::-1]

    # Initialize the new image with full transparency
    new_image_data = np.zeros((output_size[0], output_size[1], 4), dtype=np.uint8)

    # Calculate the number of transparent rows at the top
    transparent_rows = int(output_size[0] * transparency_height_fraction)

    # Fill the bottom part of the image with bright colors, leave the top part transparent
    for x in range(output_size[1]):
        # Determine a random height for colored pixels in this column
        colored_height = random.randint(transparent_rows, output_size[0])
        for y in range(output_size[0] - colored_height, output_size[0]):
            color_index = (y - (output_size[0] - colored_height)) % len(bright_colors_sorted)
            new_image_data[y, x, :3] = bright_colors_sorted[color_index][:3]
            new_image_data[y, x, 3] = 255  # Make the pixel fully opaque

    # Create the new image
    new_image = Image.fromarray(new_image_data, 'RGBA')
    return new_image

# Parameters for generation
image_path = 'yellow_fire.png'
new_image_with_colored_bottom = create_image_with_colored_bottom(image_path, (32, 32), 0.25)

# Save the generated image
new_image_path = 'yellow_fire_3.png'
new_image_with_colored_bottom.save(new_image_path)
