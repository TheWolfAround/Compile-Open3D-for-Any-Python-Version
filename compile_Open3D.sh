#!/bin/bash

# List of packages to check
packages="build-essential cmake git libc++-dev libc++abi-dev libglu1-mesa-dev"

update_package_index=0
# Loop through each package and check if it is installed
for pkg in $packages; do
    if dpkg -s "$pkg" 1> /dev/null; then
        echo "$pkg is already installed"
    else
        if [ $update_package_index -eq 0 ]; then
            sudo apt update
            update_package_index=1 #the script will update the package index once
        fi
        echo "$pkg is not installed"
        sudo apt install $pkg -y
    fi
done

# Python packages needed by the pip-package target
python_packages="numpy dash pybind11-stubgen"
PYTHON="${PYTHON:-/usr/local/bin/python3}"

for pkg in $python_packages; do
    if "$PYTHON" -m pip show "$pkg" > /dev/null 2>&1; then
        echo "$pkg is already installed"
    else
        echo "$pkg is not installed"
        "$PYTHON" -m pip install "$pkg"
    fi
done

if [ ! -d "$PWD/Compile-Vulkan-Equipments-on-Linux" ]; then
    git clone --depth 1 https://github.com/TheWolfAround/Compile-Vulkan-Equipments-on-Linux.git --recursive
else
    echo
    echo "###########################################################"
    echo "Compile-Vulkan-Equipments-on-Linux folder already exists."
    echo "###########################################################"
    echo
fi

if [ ! -d "$PWD/Open3D" ]; then
    git clone --depth 1 https://github.com/isl-org/Open3D.git --recursive
else
    echo
    echo "#############################"
    echo "Open3D folder already exists."
    echo "#############################"
    echo
fi

if [ ! -f "$PWD/Compile-Vulkan-Equipments-on-Linux/__build_out__/Release/__glslang__/bin/glslangValidator" ]; then
    echo
    echo "#####################################################################################"
    echo "* WARNING!"
    echo "  - \"glslangValidator\" not found!"
    echo "  - First run the compilation script inside the ./Compile-Vulkan-Equipments-on-Linux"
    echo "    using 'Ninja' Cmake Generator Option."
    echo "#####################################################################################"
    echo
    exit 1
fi

PROC=$(nproc)

if [ "$PROC" -gt 12 ]; then
    NUM_THREADS=6
elif [ "$PROC" -ge 8 ]; then
    NUM_THREADS=4
elif [ "$PROC" -ge 4 ]; then
    NUM_THREADS=2
else
    NUM_THREADS=1
fi

BUILD_OUT_DIR="$(pwd)/__build_out__"
BUILD_DIR="$(pwd)/__build_dir__"

rm -rf "$BUILD_DIR"

cmake -G "Unix Makefiles" \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX="$BUILD_OUT_DIR" \
    -D BUILD_PYTHON_MODULE=ON \
    -D STATIC_WINDOWS_RUNTIME=OFF \
    -D OPEN3D_GLSLANG_VALIDATOR="$(pwd)/Compile-Vulkan-Equipments-on-Linux/__build_out__/Release/__glslang__/bin/glslangValidator" \
    -D BUILD_WEBRTC=OFF \
    -D USE_SYSTEM_CURL=ON \
    -D USE_SYSTEM_OPENSSL=ON \
    -S "$(pwd)/Open3D" \
    -B "$BUILD_DIR"

cmake --build "$BUILD_DIR" --config Release --target install -j"$NUM_THREADS"
cmake --build "$BUILD_DIR" --config Release --target pip-package

cp -r "$(pwd)/__build_dir__/lib/python_package/pip_package/." "$(pwd)/"
