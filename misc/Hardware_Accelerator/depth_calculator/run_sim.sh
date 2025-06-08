#!/usr/bin/env bash
#
# run_sim.sh — build & run Verilator testbench in this folder
#
# Usage:
#   ./run_sim.sh [TOP_MODULE]
#
# If you don't pass TOP_MODULE, it defaults to "top_connection".
# It will:
#  - collect all .sv sources in the folder
#  - take TOP_MODULE.sv and TOP_MODULE.cpp as DUT and testbench
#  - build into obj_dir/
#  - run the simulation executable

set -euo pipefail

# Top-level module name (without .sv)

### TO CHANGE TO NAME ###
TOP=${1:-depth_calculator} # adjust this to 



# Collect all SV source files in this directory
SV_SOURCES=( *.sv )

# Testbench file
TB="${TOP}.cpp"

# Output directory
OBJ_DIR="obj_dir"

# Check files exist
if [ ! -f "${TOP}.sv" ]; then
  echo "Error: ${TOP}.sv not found in $(pwd)" >&2
  exit 1
fi
if [ ! -f "${TB}" ]; then
  echo "Error: Testbench ${TB} not found in $(pwd)" >&2
  exit 1
fi

# Build with Verilator
verilator \
  --cc "${SV_SOURCES[@]}" \
  --exe "${TB}" \
  --top-module "${TOP}" \
  --trace \
  --build \
  -Mdir "${OBJ_DIR}"

# Run the simulation
echo "=== Running simulation V${TOP} ==="
"${OBJ_DIR}/V${TOP}"
