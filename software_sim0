import numpy as np
import matplotlib.pyplot as plt

def mandelbrot(c, max_iter):
    z = c
    for n in range(max_iter):
        if abs(z) > 2:
            return n
        z = z*z + c
    return max_iter

def mandelbrot_set(xmin, xmax, ymin, ymax, width, height, max_iter):
    r = np.linspace(xmin, xmax, width)
    i = np.linspace(ymin, ymax, height)
    return np.array([[mandelbrot(complex(r_val, i_val), max_iter) 
                     for r_val in r] for i_val in i])

# Initial view
width, height = 800, 800
xmin, xmax = -2.0, 1.0
ymin, ymax = -1.5, 1.5
max_iter = 256

# Create plot
plt.figure(figsize=(10, 8))
mandel_img = mandelbrot_set(xmin, xmax, ymin, ymax, width, height, max_iter)
plt.imshow(mandel_img, extent=(xmin, xmax, ymin, ymax), cmap='Blues', origin='lower')
plt.colorbar(label='Iterations')
plt.title("Mandelbrot Set (Static View)")
plt.show()
