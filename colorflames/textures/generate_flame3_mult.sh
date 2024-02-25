from PIL import Image
import numpy as np
import random

def create_image_series_with_variations(image_path, output_size, transparency_height_fraction, num_images):
    images_paths = []
    original_img = Image.open(image_path).convert("RGBA")
    original_data = np.array(original_img)

    # Identify and sort colors by brightness, excluding completely transparent pixels
    colors, counts = np.unique(original_data.reshape(-1, 4), axis=0, return_counts=True)
    bright_colors = colors[np.where((colors[:,3] > 0) & ((colors[:,0] > 80) | (colors[:,1] > 80) | (colors[:,2] > 80)))]
    bright_colors_sorted = bright_colors[np.argsort(np.sum(bright_colors[:, :3], axis=1))][::-1]

    for image_idx in range(num_images):
        new_image_data = np.zeros((output_size[0], output_size[1], 4), dtype=np.uint8)
        max_colored_height = int(output_size[0] * (1 - transparency_height_fraction))

        for x in range(output_size[1]):
            # Ensure the colored height does not exceed the max_colored_height to maintain transparency
            colored_height = random.randint(0, max_colored_height)
            start_colored_y = output_size[0] - colored_height

            for y in range(start_colored_y, output_size[0]):
                color_index = (y - start_colored_y) % len(bright_colors_sorted)
                # Introduce slight variation in color
                variation_index = min(len(bright_colors_sorted) - 1, color_index + random.randint(-2, 2))
                new_image_data[y, x, :3] = bright_colors_sorted[variation_index][:3]
                new_image_data[y, x, 3] = 255

        new_image = Image.fromarray(new_image_data, 'RGBA')
        new_image_path = f'yellow_fire_{image_idx + 1}.png'
        new_image.save(new_image_path)
        images_paths.append(new_image_path)

    return images_paths

# Parameters for generation
image_path = 'yellow_fire.png'  # Update this path
num_images = 20
images_series_paths = create_image_series_with_variations(image_path, (32, 32), 0.5, num_images)

# Print the paths of the generated images
for path in images_series_paths:
    print(path)
