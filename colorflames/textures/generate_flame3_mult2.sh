from PIL import Image
import numpy as np
import math
import random

def create_image_series_with_color_gradients(image_path, output_size, transparency_height_fraction, num_images):
    images_paths = []
    original_img = Image.open(image_path).convert("RGBA")
    original_data = np.array(original_img)

    # Identify and sort colors by brightness, excluding completely transparent pixels
    colors, counts = np.unique(original_data.reshape(-1, 4), axis=0, return_counts=True)
    bright_colors = colors[np.where((colors[:,3] > 0) & ((colors[:,0] > 80) | (colors[:,1] > 80) | (colors[:,2] > 80)))]
    # Sort colors from dark to bright for vertical gradient
    colors_sorted_by_brightness = bright_colors[np.argsort(np.sum(bright_colors[:, :3], axis=1))]

    for image_idx in range(num_images):
        # Randomly select frequency and amplitude_factor for each image
        frequency = random.uniform(1, 5)  # Fits 3 to 6 sine waves within the image width
        amplitude_factor = random.uniform(1/3, 2/3)  # Allows wave height to vary significantly

        new_image_data = np.zeros((output_size[0], output_size[1], 4), dtype=np.uint8)
        wave_height_range = int(output_size[0] * amplitude_factor)

        for x in range(output_size[1]):
            angle = 2 * math.pi * frequency * (x / float(output_size[1]))
            sine_value = math.sin(angle)
            wave_height = int(wave_height_range * (sine_value + 1) / 2)
            min_colored_height = int(output_size[0] * (1 - transparency_height_fraction - amplitude_factor/2))
            colored_height = min_colored_height + wave_height

            for y in range(output_size[0] - colored_height, output_size[0]):
                # Map y-coordinate to color brightness, darker at the top
                brightness_index = int((y - (output_size[0] - colored_height)) / colored_height * len(colors_sorted_by_brightness))
                color_index = max(0, min(len(colors_sorted_by_brightness) - 1, brightness_index))
                new_image_data[y, x, :3] = colors_sorted_by_brightness[color_index][:3]
                new_image_data[y, x, 3] = 255

        new_image = Image.fromarray(new_image_data, 'RGBA')
        new_image_path = f'yellow_fire_{image_idx + 1}.png'
        new_image.save(new_image_path)
        images_paths.append(new_image_path)

    return images_paths

# Parameters for generation
image_path = 'yellow_fire.png'  # Ensure this path points to your original image
num_images = 20

images_series_paths = create_image_series_with_color_gradients(image_path, (32, 32), 0.25, num_images)

# Print the paths of the generated images
for path in images_series_paths:
    print(path)
