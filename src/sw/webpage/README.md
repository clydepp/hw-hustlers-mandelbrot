# Webpage and webserver implementations
## Usage
To be able to run the webpage (UI) ensure you have node.js installed. This can be done for most environments. I won't leave the install instructions here.

SolidJS, Tailwind and Electron must be installed in order to run, build or deploy the webpage. For a quick solution run:
```
npm install
```
in the terminal.

To run the webpage locally (in dev mode):
```
npm run build
npm run electron-dev
```
The latter command can be written as `npm run dev` to run the software in the default browser.

Install any required Python dependencies and libaries, common ones are `opencv-python`, `numpy` and `websockets`. Run both the `coloured_bytes.py` and `new_hand_recog.py` programs at the same time. This can be done in two different terminals by running these commands:
```
cd webpage/py
python <file_name>.py
```

When all components in the software system are running, the UI, Python scripts and Jupyter notebook (FPGA) should connect and work as desired. Have fun!

