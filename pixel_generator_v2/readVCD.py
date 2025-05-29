from vcdvcd import VCDVCD
from  PIL import Image
import os
import csv

# Get the directory where the script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
width, height = 640, 480
image = Image.new('RGB', (width, height))
pixels = image.load()

vcd_path = os.path.join(script_dir, "AXIS_tb_new.vcd")

vcd = VCDVCD(vcd_path)

# List all human readable signal names.
#print(vcd.references_to_ids.keys())

r = 'TOP.top.p1.r[7:0]'
b = 'TOP.top.p1.b[7:0]'
g = 'TOP.top.p1.g[7:0]'
xCount = 'TOP.top.p1.x[9:0]'
yCount = 'TOP.top.p1.y[8:0]'
sof = 'TOP.top.sof'

# Get the signal for xCount
signal_xCount = vcd[xCount]

# Get a list for the time value delta pairs for xCount
x_tv = signal_xCount.tv
y_tv = vcd[yCount].tv
sof_tv = vcd[sof].tv
    
# Get a list of time value delta pairs for r, b, g    
r_tv = vcd[r].tv
b_tv = vcd[b].tv
g_tv = vcd[g].tv

# # Helper to get the latest value at or before a given time
# def get_latest(tv, t):
#     val = None
#     for time, v in tv:
#         if time > t:
#             break
#         val = v
#     return int(val, 2) if val is not None else None

# # Print header
# print("time,xCount,r,g,b")

# firstTime = True
# newFrame = False

# last_x = None
# for t, x_val in x_tv:
#     # Check if the start of frame signal is high
#     # If it is, we can ignore the rest of the signals
#     if not firstTime and get_latest(sof_tv, t) == 1:
#         newFrame = True
#         firstTime = False
#         print(f"New frame at time {t}")
#     if newFrame:
#         break
#     x_int = int(x_val, 2)
#     if x_int != last_x:
#         r_val = get_latest(r_tv, t)
#         g_val = get_latest(g_tv, t)
#         b_val = get_latest(b_tv, t)
#         y_val = get_latest(y_tv, t)
#         #print(f"{t},{x_int},{y_val},{r_val},{g_val},{b_val}")
#         last_x = x_int

r_idx = g_idx = b_idx = y_idx = sof_idx = 0
r_val = int(r_tv[0][1], 2)
g_val = int(g_tv[0][1], 2)
b_val = int(b_tv[0][1], 2)
y_val = int(y_tv[0][1], 2)
sof_val = int(sof_tv[0][1], 2)

firstTime = True
newFrame = False
last_x = None

for t, x_val in x_tv:
    # Advance each pointer to the latest value at or before t
    while r_idx + 1 < len(r_tv) and r_tv[r_idx + 1][0] <= t:
        r_idx += 1
        r_val = int(r_tv[r_idx][1], 2)
    while g_idx + 1 < len(g_tv) and g_tv[g_idx + 1][0] <= t:
        g_idx += 1
        g_val = int(g_tv[g_idx][1], 2)
    while b_idx + 1 < len(b_tv) and b_tv[b_idx + 1][0] <= t:
        b_idx += 1
        b_val = int(b_tv[b_idx][1], 2)
    while y_idx + 1 < len(y_tv) and y_tv[y_idx + 1][0] <= t:
        y_idx += 1
        y_val = int(y_tv[y_idx][1], 2)
    while sof_idx + 1 < len(sof_tv) and sof_tv[sof_idx + 1][0] <= t:
        sof_idx += 1
        sof_val = int(sof_tv[sof_idx][1], 2)

    x_int = int(x_val, 2)
    
    if x_int == 0 and y_val ==0:
        if firstTime:
            firstTime = False
            print(f"First SOF at time {t} (ignored for data)")
        else:
            print(f"New frame at time {t}")
            break
    
    
    if x_int != last_x:
        pixels[x_int, y_val] = (r_val, g_val, b_val)
        #print(f"{t},{x_int},{y_val},{r_val},{g_val},{b_val}")
        last_x = x_int
    
print("Done")
output_path = os.path.join(script_dir, "output.png")
image.save(output_path)
print(f"Image saved to {output_path}")