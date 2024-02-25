from PIL import Image
import numpy as np
import random

def create_diverse_color_image(image_path, output_size, transparency_fraction):
    # Load the original image
    img = Image.open(image_path)
    img_data = np.array(img)

    # Identify the unique colors in the image, excluding fully transparent ones
    colors, counts = np.unique(img_data.reshape(-1, 4), axis=0, return_counts=True)
    # Filter out colors based on visibility and diversity
    visible_colors = colors[colors[:, 3] > 0]  # Exclude fully transparent
    diverse_colors = visible_colors[(visible_colors[:, :3].std(axis=1) > 30) | (visible_colors[:, 3] == 255)]  # Color diversity

    # New image data
    new_img_data = np.zeros((output_size[0], output_size[1], 4), dtype=np.uint8)

    # Calculate the transparent region height
    transparent_height = int(output_size[0] * transparency_fraction)

    # Distribution of colors from the bottom
    for x in range(output_size[1]):
        color_height = random.randint(transparent_height, output_size[0])
        for y in range(output_size[0] - color_height, output_size[0]):
            color_choice = random.choice(diverse_colors)
            new_img_data[y, x] = color_choice

    new_img = Image.fromarray(new_img_data, 'RGBA')
    return new_img

# Parameters
image_path = 'yellow_fire.png'
output_size = (32, 32)
transparency_fraction = 0.25

# Generate the image
new_img_with_diverse_colors = create_diverse_color_image(image_path, output_size, transparency_fraction)

# Save the image
new_img_path = 'yellow_fire_amin2.png'
new_img_with_diverse_colors.save(new_img_path)
