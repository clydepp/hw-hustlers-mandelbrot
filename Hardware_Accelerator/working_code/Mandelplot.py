import csv
from PIL import Image

# Image size
width, height = 960, 720
image = Image.new("RGB", (width, height))
pixels = image.load()

# Load CSV
with open("pixels.csv", newline='') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        x = int(row["x"])
        y = int(row["y"])
        r = int(row["r"])
        g = int(row["g"])
        b = int(row["b"])
        if 0 <= x < width and 0 <= y < height:
            pixels[x, y] = (r, g, b)

# Save output
image.save("output_from_csv.png")
print("Image saved to output_from_csv.png")
