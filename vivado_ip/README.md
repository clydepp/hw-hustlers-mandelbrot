# Vivado IP

This folder contains the required files for updating the `pixel_generator_1.0` folder in the Vivado project.

## Steps

1. Follow the base repo instructions to set up Vivado.
2. Replace the original `pixel_generator_1.0` folder in your Vivado project with the one in this folder. 
3. Follow the <b>Rebuilding the Pixel Generator IP </b> steps, completing step 2. 
4. In the <i>Sources</i> tab, click the plus button and add all your new design files from the newly copied `pixel_generator_1.0` folder including the `.mem` file. 
    - If it tells you: 'you can't scan and copy, they're mutually exclusive', untick the second box that says to copy the IP. Only have the scan and import into the project ticked, from the choices that you can change. 
5. You will find that all the `.v` and `.sv` files will add themselves automatically. However, adding the `.mem` file is a little bit different. 
    - In the package IP tab, the same tab where you can click <b>Review and Package</b>, click <b>File Groups</b>.
    - In the <b>Standard</b> folder, expand it and you will see both a <b>Synthesis</b> and a <b>Simulation</b> folder. You must add the `.mem` file to both of these parts. 
    - Right click on one of the folders and click <b>'Add Files'</b>
    - Find and select the `color_lut.mem` file. If you cannot see it change the <b>'Files of type:'</b> to <b>'All Files'</b>. And then press open. 
    - Repeat for the other folder. You will see that the `.mem` file is included with all your other RTL files. 
6. Continue and follow the steps from the base repo from step 3. 

### Changes made to fix the errors

- Changed necessary `regs` to `wires` when it is an output of a submodule
- Removed double assignment of `ready` signal in `pixel_generator.v`
- Removed `always_ff` blocks and changed to `always`
- Removed enums