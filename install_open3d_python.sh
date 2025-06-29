#!/usr/bin/env bash
# Author: Luigi Freda 
# Author: Luigi Freda 
# This file is part of https://github.com/luigifreda/pyslam

#set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # get script dir
SCRIPT_DIR=$(readlink -f $SCRIPT_DIR)  # this reads the actual path if a symbolic directory is used

ROOT_DIR="$SCRIPT_DIR"

# ====================================================
# import the bash utils 
. "$ROOT_DIR"/bash_utils.sh 

# ====================================================

# NOTE: this is required under mac where I got unexpected segmentation fault errors
#       on open3d dynamic library loading

STARTING_DIR=`pwd`  
cd "$ROOT_DIR"  

print_blue "Installing open3d-python from source"

if [[ $OSTYPE == "darwin"* ]]; then
    EXTERNAL_OPTIONS="$EXTERNAL_OPTIONS -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
fi

#pip3 install --upgrade pip
pip3 uninstall -y open3d

cd thirdparty
if [ ! -d open3d ]; then
    git clone https://github.com/isl-org/Open3D.git open3d
    cd open3d
    
    # This commit 0f06a149c4fb9406fd3e432a5cb0c024f38e2f0e didn't work. It corresponds to open3d 0.18.0 -> https://github.com/isl-org/Open3D/commits/v0.18.0
    #git checkout 0f06a149c4fb9406fd3e432a5cb0c024f38e2f0e 

    # This commit worked!
    git checkout 997f04eece54b3735fe08350fc0113dba651039b

    if [[ $OSTYPE == "darwin"* ]]; then
        git apply ../open3d.patch
    fi

    cd ..
fi

cd open3d
if [ ! -d build ]; then
    mkdir build 
fi 

cd build
cmake .. -DCMAKE_BUILD_TYPE=Release $MAC_OPTIONS $EXTERNAL_OPTIONS

if [[ $OSTYPE == "darwin"* ]]; then
    make -j$(sysctl -n hw.physicalcpu)
else 
    make -j$(nproc)
fi

# Activate the virtualenv first
# Install pip package in the current python environment
make install-pip-package

# Create Python package in build/lib
make python-package

# Create pip wheel in build/lib
# This creates a .whl file that you can install manually.
make pip-package


sudo make install

cd "$STARTING_DIR"