#!/bin/bash

# Check if Python is installed
if ! command -v python &> /dev/null
then
    echo "Python is not installed."
    exit 1
fi

# Get Python library path
PYTHON_LIB_PATH=$(python -c "import sys; print(sys.path)")

# Print the library path
echo "Python Library Path:"
echo "$PYTHON_LIB_PATH"

