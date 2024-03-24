from PIL import Image
import numpy as np
import math
import random

def calculate_frequency():
    """
    A generator that cycles through frequencies 0.5, 1, 1.5, ..., up to 3, 
    then reverses back down to 0.5 in steps of 0.5, and repeats.
    """
    direction = 1  # Start by incrementing
    frequency = 0.3
    while True:
        yield frequency
        if frequency >= 0.8 and direction == 1:
            direction = -1  # Start decrementing
        elif frequency <= 0.3 and direction == -1:
            direction = 1  # Start incrementing again
        frequency += 0.05 * direction

def calculate_brightness(color):
    # Simple weighted approach to calculate brightness
    return color[0] * 0.299 + color[1] * 0.587 + color[2] * 0.114

def find_most_contrasting_colors(colors):
    max_contrast = 0
    contrasting_pair = (colors[0], colors[1])
    for i in range(len(colors)):
        for j in range(i + 1, len(colors)):
            brightness_diff = abs(calculate_brightness(colors[i]) - calculate_brightness(colors[j]))
            if brightness_diff > max_contrast:
                max_contrast = brightness_diff
                contrasting_pair = (colors[i], colors[j])
    return contrasting_pair

def create_image_series_with_contrasting_colors(image_path, output_size, transparency_height_fraction, num_images):
    images_paths = []
    original_img = Image.open(image_path).convert("RGBA")
    original_data = np.array(original_img)

    colors, counts = np.unique(original_data.reshape(-1, 4), axis=0, return_counts=True)
    visible_colors = colors[colors[:,3] > 0]

    # Find the two most contrasting colors
    color_start, color_end = find_most_contrasting_colors(visible_colors[:, :3])

    # Ensure color_start is brighter than color_end
    if calculate_brightness(color_start) < calculate_brightness(color_end):
        color_start, color_end = color_end, color_start  # Swap

    frequency_generator = calculate_frequency()  # Initialize the frequency generator

    for image_idx in range(1, num_images + 1):
        frequency = next(frequency_generator)
        amplitude_factor = random.uniform(1/3, 2/3)

        new_image_data = np.zeros((output_size[0], output_size[1], 4), dtype=np.uint8)
        wave_height_range = int(output_size[0] * amplitude_factor)

        for x in range(output_size[1]):
            angle = 2 * math.pi * frequency * (x / float(output_size[1]))
            sine_value = math.sin(angle)
            wave_height = int(wave_height_range * (sine_value + 1) / 2)
            min_colored_height = int(output_size[0] * (1 - transparency_height_fraction - amplitude_factor/2))
            colored_height = min_colored_height + wave_height

            for y in range(output_size[0] - colored_height, output_size[0]):
                ratio = (y - (output_size[0] - colored_height)) / colored_height
                interpolated_color = [int(ratio * color_start[j] + (1 - ratio) * color_end[j]) for j in range(3)]
                new_image_data[y, x, :3] = interpolated_color
                new_image_data[y, x, 3] = 255

        new_image = Image.fromarray(new_image_data, 'RGBA')
        new_image_path = f'green_fire_{image_idx}.png'
        new_image.save(new_image_path)
        images_paths.append(new_image_path)

    return images_paths

# Parameters for generation
image_path = 'green_fire_inv.png'  # Ensure this path points to your original image
num_images = 20  # Total number of images to generate

images_series_paths = create_image_series_with_contrasting_colors(image_path, (64, 64), 0.55, num_images)

# Print the paths of the generated images
for path in images_series_paths:
    print(path)
