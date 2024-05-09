#!/bin/bash

# Define paths
SCRIPT_PATH="$(dirname "$(realpath "$0")")"
SCRIPT_NAME="$(basename "$0")"
HAIKU_TOOLCHAIN="$SCRIPT_PATH/buildtools"
HAIKU_BINARIES="$SCRIPT_PATH/haiku_binaries"

# Create directories if they don't exist
mkdir -p "$HAIKU_TOOLCHAIN"
mkdir -p "$HAIKU_BINARIES"

# Function to download the Haiku build tools
download_haiku_toolchain() {
    cd "$HAIKU_TOOLCHAIN" || { echo "Error: Could not change directory to $HAIKU_TOOLCHAIN"; exit 1; }
    git clone https://review.haiku-os.org/buildtools
}

# Function to display dialog and get Linux binary path
get_linux_binary_path() {
    linux_binary_path=$(hey prompt "Enter the path to the Linux binary:")
    if [[ -z "$linux_binary_path" ]]; then
        hey alert "No path entered. Please try again."
        get_linux_binary_path
    fi
}

# Function to display dialog and get output directory path
get_output_directory() {
    output_dir=$(hey filesave "Select output directory for Haiku binary:" -i "$HAIKU_BINARIES")
    if [[ -z "$output_dir" ]]; then
        hey alert "No directory selected. Please try again."
        get_output_directory
    fi
}

# Function to cross-compile the Linux binary to Haiku
cross_compile_binary() {
    haiku_compiler_target="$(hey list "Select Haiku target architecture:" "x86_gcc2" "x86_64_gcc2" "arm_gcc2")"

    if [[ -z "$haiku_compiler_target" ]]; then
        hey alert "No target architecture selected. Aborting."
        return 1
    fi

    # Set up variables
    haiku_prefix="$HAIKU_TOOLCHAIN/${haiku_compiler_target}"
    haiku_sysroot="${haiku_prefix}/system"
    haiku_compiler="${haiku_prefix}/bin/${haiku_compiler_target}-gcc"

    # Cross-compile the Linux binary to Haiku
    ${haiku_compiler} --sysroot=${haiku_sysroot} "$linux_binary_path" -o "${output_dir}/haiku_binary"

    # Check if compilation was successful
    if [ $? -eq 0 ]; then
        hey info "Haiku binary successfully created: ${output_dir}/haiku_binary"
    else
        hey alert "Error: Failed to create Haiku binary"
    fi
}

# Main function
main() {
    download_haiku_toolchain
    get_linux_binary_path
    get_output_directory
    cross_compile_binary
}

# Execute main function
main
