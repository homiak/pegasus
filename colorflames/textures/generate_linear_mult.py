from PIL import Image
import numpy as np
import random

def create_image_series_with_variations(image_path, output_size, transparency_height_fraction, num_images, max_variation=2):
    images_paths = []
    original_img = Image.open(image_path).convert("RGBA")
    original_data = np.array(original_img)

    # Identify and sort colors by brightness, excluding completely transparent pixels
    colors, counts = np.unique(original_data.reshape(-1, 4), axis=0, return_counts=True)
    bright_colors = colors[np.where((colors[:,3] > 0) & ((colors[:,0] > 80) | (colors[:,1] > 80) | (colors[:,2] > 80)))]
    bright_colors_sorted = bright_colors[np.argsort(np.sum(bright_colors[:, :3], axis=1))][::-1]

    # Initialize column heights for the seed image within 20% of the image height
    max_colored_height = output_size[0] - int(output_size[0] * transparency_height_fraction)
    base_height = max_colored_height // 2  # Base height for all columns
    height_variation_limit = int(output_size[0] * 0.2)  # Max variation is 20% of the image height

    initial_colored_heights = [
        max(0, min(max_colored_height, base_height + random.randint(-height_variation_limit, height_variation_limit)))
        for _ in range(output_size[1])
    ]

    for image_idx in range(num_images):
        new_image_data = np.zeros((output_size[0], output_size[1], 4), dtype=np.uint8)
        
        for x in range(output_size[1]):
            if image_idx == 0:
                colored_height = initial_colored_heights[x]
            else:
                # For subsequent images, adjust the height slightly to ensure gradual changes
                variation = random.randint(-max_variation, max_variation)
                colored_height = max(0, min(max_colored_height, initial_colored_heights[x] + variation))
                initial_colored_heights[x] = colored_height  # Update for gradual change
            
            for y in range(output_size[0] - colored_height, output_size[0]):
                color_index = (y - (output_size[0] - colored_height)) % len(bright_colors_sorted)
                variation_index = min(len(bright_colors_sorted) - 1, color_index + random.randint(-2, 2))
                new_image_data[y, x, :3] = bright_colors_sorted[variation_index][:3]
                new_image_data[y, x, 3] = 255

        new_image = Image.fromarray(new_image_data, 'RGBA')
        new_image_path = f'yellow_fire_{image_idx + 1}.png'
        new_image.save(new_image_path)
        images_paths.append(new_image_path)

    return images_paths

# Parameters for generation
image_path = 'yellow_fire_inv.png'  # Update this path
num_images = 20
images_series_paths = create_image_series_with_variations(image_path, (64, 64), 0.25, num_images)

# Print the paths of the generated images
for path in images_series_paths:
    print(path)
