#!/bin/bash

# Script to compile all .tlhe benchmarks to .vhe format
# Usage: ./scripts/compile_viaduct_benchmarks.sh [size]
#   size: vector size (n) to use, defaults to 8192
#   If no size specified, compiles with both 8192 and 32768

set -e

VIADUCT_DIR="../viaduct-he"
APPS_DIR="viaduct_apps"
OUTPUT_DIR="viaduct_benchmarks"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to compile a benchmark
# Arguments: input_file, output_name, epochs, duration, size
compile_benchmark() {
    local input_file="$1"
    local output_name="$2"
    local epochs="$3"
    local duration="$4"
    local size="$5"
    
    local input_path="$APPS_DIR/$input_file"
    local size_suffix=""
    if [ "$size" != "8192" ]; then
        size_suffix="_${size}"
    fi
    local output_path="$OUTPUT_DIR/${output_name}_e${epochs}_o${duration}${size_suffix}.vhe"
    
    echo "Compiling $input_file -> ${output_name}_e${epochs}_o${duration}${size_suffix}.vhe (size=$size)"
    
    viaducthe "$input_path" \
        -o "$output_path" \
        -e "$epochs" \
        -d "$duration" \
        -b dummy \
        --size "$size"
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Success: $output_path"
    else
        echo "  ✗ Failed: $input_file"
        return 1
    fi
}

# Function to compile a benchmark with all configurations
# Arguments: input_file, output_name
compile_all_configs() {
    local input_file="$1"
    local output_name="$2"
    local size="$3"
    
    # Compile with e1_o0
    compile_benchmark "$input_file" "$output_name" 1 0 "$size"
    
    # Compile with e2_o1
    compile_benchmark "$input_file" "$output_name" 2 1 "$size"
}

# Determine which sizes to compile
if [ -n "$1" ]; then
    # Single size specified
    SIZES=("$1")
else
    # Default: compile with both 8192 and 32768
    SIZES=(8192 32768)
fi

# Compile all benchmarks with each size
for size in "${SIZES[@]}"; do
    echo ""
    echo "=== Compiling with size=$size ==="
    
    # Compile each benchmark with all configurations (e1_o0 and e2_o1)
    compile_all_configs "matmul_128_64.tlhe" "matmul_128_64" "$size"
    compile_all_configs "matmul_256_128.tlhe" "matmul_256_128" "$size"
    compile_all_configs "double_matmul_128_64.tlhe" "double_matmul_128_64" "$size"
    compile_all_configs "double_matmul_256_128.tlhe" "double_matmul_256_128" "$size"
    compile_all_configs "ttm.tlhe" "ttm" "$size"
    compile_all_configs "conv_8_32.tlhe" "conv_8_32" "$size"
    compile_all_configs "conv_8_64.tlhe" "conv_8_64" "$size"
    compile_all_configs "logreg_matvecmul.tlhe" "logreg_matvecmul" "$size"
    compile_all_configs "bert_attention.tlhe" "bert_attention" "$size"
done

echo ""
echo "=== Compilation complete ==="
echo "Output files are in: $OUTPUT_DIR"
echo ""
echo "Files compiled with size 8192 have no suffix."
echo "Files compiled with size 32768 have '_32768' suffix."
