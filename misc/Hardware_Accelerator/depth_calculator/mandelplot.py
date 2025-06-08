import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# Read the CSV
df = pd.read_csv('mandelbrot.csv')

# Pivot to create a 2D array of depths
depth_array = df.pivot(index='y', columns='x', values='depth').values

# Plot the array
plt.figure(figsize=(8, 6))
plt.imshow(depth_array, origin='lower', aspect='auto')
plt.title('Mandelbrot Set Depth')
plt.xlabel('Pixel X')
plt.ylabel('Pixel Y')
plt.colorbar(label='Iteration Depth')
plt.tight_layout()
plt.show()