#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <testbench_dir> [top_module]" >&2
  exit 1
fi

TB_DIR="$1"
DEFAULT_TOP="$(basename "$TB_DIR")"
TOP="${2:-$DEFAULT_TOP}"

RTL_DIR="RTL"

# Sanity
if [ ! -d "$TB_DIR" ]; then
  echo "ERROR: testbench dir '$TB_DIR' not found." >&2
  exit 1
fi
if [ ! -f "${TB_DIR}/${TOP}.cpp" ]; then
  echo "ERROR: testbench file '${TB_DIR}/${TOP}.cpp' not found." >&2
  exit 1
fi
if [ ! -f "${RTL_DIR}/${TOP}.sv" ]; then
  echo "ERROR: RTL file '${RTL_DIR}/${TOP}.sv' not found." >&2
  exit 1
fi

# Move into testbench folder
pushd "$TB_DIR" > /dev/null

# Clean previous build
rm -rf obj_dir
rm -f waveform.vcd

# Run Verilator from inside TB_DIR, pointing at RTL up one level
verilator --cc   ../${RTL_DIR}/*.sv \
          --exe  ${TOP}.cpp     \
          --top-module ${TOP}   \
          --trace                \
          --build                \
          -Mdir obj_dir

# Run the simulation
echo "=== Running V${TOP} in ${TB_DIR}/obj_dir ==="
obj_dir/V${TOP}

# Return
popd > /dev/null
