# x, y are coordinates within the canvas 640x480
from qformatpy import qformat

def zoom_at_cursor(mouse_x, mouse_y, zoom,
                   screen_width, screen_height,
                   view_min_x, view_max_x, view_min_y, view_max_y):

    # Map mouse to complex coordinates
    cursor_re = view_min_x + (mouse_x / screen_width) * (view_max_x - view_min_x)
    cursor_im = view_min_y + (mouse_y / screen_height) * (view_max_y - view_min_y)

    # New width and height of the complex plane
    new_width = (view_max_x - view_min_x) * zoom
    new_height = (view_max_y - view_min_y) * zoom

    # Recenter the view around the cursor
    new_min_x = cursor_re - new_width / 2
    new_max_x = cursor_re + new_width / 2
    new_min_y = cursor_im - new_height / 2
    new_max_y = cursor_im + new_height / 2

    return qformat(cursor_re, qi=4, qf=28, rnd_method='Trunc'), qformat(cursor_im, qi=4, qf=28, rnd_method='Trunc')

screen_width, screen_height = 640, 480
initial_view = (-2.0, 1.0, -1.5, 1.5)

# 1. Zoom in at center of 640x480
result1 = zoom_at_cursor(255, 240, 0.9, screen_width, screen_height, *initial_view)
print("Zoom 1 (center, zoom in):", result1)

# 2. Zoom out at top-left (0,0)
result2 = zoom_at_cursor(0, 0, 1.1, screen_width, screen_height, *initial_view)
print("Zoom 2 (top-left, zoom out):", result2)

# 3. Zoom in on right-center (near edge)
result3 = zoom_at_cursor(600, 240, 0.8, screen_width, screen_height, *initial_view)
print("Zoom 3 (right-center, zoom in):", result3)

# 4. Zoom in near bottom-center
result4 = zoom_at_cursor(320, 460, 0.85, screen_width, screen_height, *initial_view)
print("Zoom 4 (bottom-center, zoom in):", result4)

# 5. Slight zoom out at arbitrary point (left third)
result5 = zoom_at_cursor(200, 100, 1.02, screen_width, screen_height, *initial_view)
print("Zoom 5 (upper-leftish, zoom out):", result5)