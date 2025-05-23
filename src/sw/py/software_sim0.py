import numpy as np
import matplotlib.pyplot as plt
from matplotlib.widgets import RectangleSelector

def mandelbrot(c, max_iter):
    """Calculate if a point is in the Mandelbrot set"""
    z = c
    for n in range(max_iter):
        if abs(z) > 2:
            return n
        z = z*z + c
    return max_iter

def mandelbrot_set(xmin, xmax, ymin, ymax, width, height, max_iter):
    """Create a Mandelbrot set image"""
    r1 = np.linspace(xmin, xmax, width)
    r2 = np.linspace(ymin, ymax, height)
    return np.array([[mandelbrot(complex(r, i), max_iter) 
                     for r in r1] for i in r2])

def onselect(eclick, erelease):
    """Handle zoom selection"""
    x1, y1 = eclick.xdata, eclick.ydata
    x2, y2 = erelease.xdata, erelease.ydata
    
    # Update the plot with the new coordinates
    update_plot(x1, x2, y1, y2)

def update_plot(x1, x2, y1, y2):
    """Update the plot with new coordinates"""
    global img, ax
    
    # Ensure we have valid coordinates
    if None in (x1, x2, y1, y2):
        return
    
    # Make sure x1 < x2 and y1 < y2
    x1, x2 = min(x1, x2), max(x1, x2)
    y1, y2 = min(y1, y2), max(y1, y2)
    
    # Calculate the new image
    mandel_img = mandelbrot_set(x1, x2, y1, y2, width, height, max_iter)
    
    # Update the image data
    img.set_data(mandel_img)
    img.set_extent((x1, x2, y1, y2))
    
    # Redraw
    ax.figure.canvas.draw_idle()

# Initial parameters
width, height = 800, 800
max_iter = 48 # cap the iteration count

# Initial view of the Mandelbrot set
xmin, xmax = -2.0, 1.0
ymin, ymax = -1.5, 1.5

# Create the initial plot
fig, ax = plt.subplots(figsize=(10, 10))
mandel_img = mandelbrot_set(xmin, xmax, ymin, ymax, width, height, max_iter)
img = ax.imshow(mandel_img, extent=(xmin, xmax, ymin, ymax), cmap='hot', origin='lower')

# Add rectangle selector for zooming
rs = RectangleSelector(ax, onselect, useblit=True,
                       button=[1],  # Left mouse button
                       minspanx=5, minspany=5,
                       spancoords='pixels',
                       interactive=True)

plt.title("Click and drag to zoom. Right-click to reset.")
plt.colorbar(img, ax=ax, label='Iterations')
plt.show()
