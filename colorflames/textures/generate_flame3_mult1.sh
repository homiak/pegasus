from PIL import Image
import numpy as np
import math
import random

def create_image_series_with_dynamic_sine_variations(image_path, output_size, transparency_height_fraction, num_images):
    images_paths = []
    original_img = Image.open(image_path).convert("RGBA")
    original_data = np.array(original_img)

    # Identify and sort colors by brightness, excluding completely transparent pixels
    colors, counts = np.unique(original_data.reshape(-1, 4), axis=0, return_counts=True)
    bright_colors = colors[np.where((colors[:,3] > 0) & ((colors[:,0] > 80) | (colors[:,1] > 80) | (colors[:,2] > 80)))]
    bright_colors_sorted = bright_colors[np.argsort(np.sum(bright_colors[:, :3], axis=1))][::-1]

    for image_idx in range(num_images):
        # Randomly select frequency for each image
        frequency = random.uniform(3, 6)  # Fits 3 to 6 sine waves within the image width
        
        # Adjust amplitude_factor to achieve an average height of 2/3 of the image
        amplitude_factor = random.uniform(1/3, 2/3)  # Allows wave height to vary more significantly

        new_image_data = np.zeros((output_size[0], output_size[1], 4), dtype=np.uint8)
        wave_height_range = int(output_size[0] * amplitude_factor)  # Max variation in wave height

        # Calculate the minimum colored height to ensure the average height is around 2/3 of the image
        min_colored_height = int(output_size[0] * (1 - transparency_height_fraction - amplitude_factor/2))

        for x in range(output_size[1]):
            # Calculate dynamic column height based on sine function
            angle = 2 * math.pi * frequency * (x / float(output_size[1]))
            sine_value = math.sin(angle)
            # Adjust the wave height within the specified range
            wave_height = int(wave_height_range * (sine_value + 1) / 2)
            colored_height = min_colored_height + wave_height

            for y in range(output_size[0] - colored_height, output_size[0]):
                color_index = (y - (output_size[0] - colored_height)) % len(bright_colors_sorted)
                new_image_data[y, x, :3] = bright_colors_sorted[color_index][:3]
                new_image_data[y, x, 3] = 255

        new_image = Image.fromarray(new_image_data, 'RGBA')
        new_image_path = f'yellow_fire_{image_idx + 1}.png'  # Update the path as needed
        new_image.save(new_image_path)
        images_paths.append(new_image_path)

    return images_paths

# Parameters for generation
image_path = 'yellow_fire.png'  # Update this path to your original image
num_images = 10

images_series_paths = create_image_series_with_dynamic_sine_variations(image_path, (32, 32), 0.25, num_images)

# Print the paths of the generated images
for path in images_series_paths:
    print(path)
