# Software implementation

## Cython
Initial versions of the code were written in Python and translated/compiled into Cython.

To install Cython (and if you already have `pip` installed), run below in the terminal:
```
pip install Cython
```

To compile Python files, make sure to `import cython` and save code in a `.pyx` format. Make a `setup.py` file (an example can be seen in the repo) and for the command step, run this line:
```
python setup.py build_ext --inplace
```

The Cythonized file can be run on a Python file that does `import <filename>` and `<filename>.count_increases(input_depths)`.
