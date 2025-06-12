import csv
from PIL import Image
import matplotlib.cm as cm

import matplotlib.pyplot as plt
colormap = plt.get_cmap("turbo_r")


# Image size
width, height = 960, 720
image = Image.new("RGB", (width, height))
pixels = image.load()

# Use modern way to get colormap (Matplotlib >=3.7)
# colormap = cm.colormaps["turbo"]

# Load CSV
with open("pixels.csv", newline='') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        x = int(row["x"])
        y = int(row["y"])
        value = float(row["r"]) / 255.0  # Normalized from 0–255 to 0–1

        # Get RGB from colormap
        rgba = colormap(value)
        r, g, b = [int(255 * c) for c in rgba[:3]]

        if 0 <= x < width and 0 <= y < height:
            pixels[x, y] = (r, g, b)

# Save output
image.save("output_colormapped.png")
print("Image saved to output_colormapped.png")
