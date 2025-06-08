#!/bin/bash

# Check if a filename is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <vcd_file>"
  exit 1
fi

VCD_FILE="$1"

# Check if the file exists
if [ ! -f "$VCD_FILE" ]; then
  echo "Error: File '$VCD_FILE' not found!"
  exit 1
fi

# Open GTKWave with the file
gtkwave "$VCD_FILE"
