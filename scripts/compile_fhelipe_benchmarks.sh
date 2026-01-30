#!/bin/bash

# Script to compile all FHELIPE benchmarks
# Usage: ./scripts/compile_fhelipe_benchmarks.sh [size]
#   size: ring size (n) to use, defaults to 8192
#   If no size specified, compiles with both 8192 and 32768

set -e

# Paths - adjust these if needed
FHELIPE_DIR="${FHELIPE_DIR:-../fhelipe}"
APPS_DIR="fhelipe_apps"
OUTPUT_DIR="fhelipe_benchmarks"
EXPERIMENTS_BASE="${EXPERIMENTS_BASE:-/tmp/fhelipe_experiments}"

# Compile binary path
COMPILE_BIN="${FHELIPE_DIR}/backend/release/compile"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to compile a benchmark
# Arguments: python_file, benchmark_name, size, exe_folder_suffix, log_chunk_size, [usable_levels] [python_args]
compile_benchmark() {
    local python_file="$1"
    local benchmark_name="$2"
    local size="$3"
    local exe_folder_suffix="$4"
    local log_chunk_size="$5"
    local usable_levels="${6:-10}"  # Default to 10 if not specified
    local python_args="${7:-}"      # Optional additional Python arguments
    
    local python_path="${FHELIPE_DIR}/frontend/fheapps/rotom/${python_file}"
    local experiment_root="${EXPERIMENTS_BASE}/rotom_${benchmark_name}"
    
    # Handle empty exe_folder_suffix (for benchmarks that use root/shared)
    if [ -z "$exe_folder_suffix" ]; then
        local exe_folder="${experiment_root}/shared"
    else
        local exe_folder="${experiment_root}/${exe_folder_suffix}/shared"
    fi
    
    # Determine size suffix for output directory
    local size_suffix=""
    if [ "$size" != "8192" ]; then
        size_suffix="_${size}"
    fi
    local output_dir="${OUTPUT_DIR}/${benchmark_name}${size_suffix}"
    
    echo "Compiling ${python_file} -> ${benchmark_name}${size_suffix} (size=$size)"
    echo "  Experiment root: $experiment_root"
    echo "  Exe folder: $exe_folder"
    
    # Step 1: Run Python script to generate TDF
    if [ ! -f "$python_path" ]; then
        echo "  ✗ Python file not found: $python_path"
        return 1
    fi
    
    echo "  Step 1: Running Python frontend..."
    # Build Python command with optional arguments
    local python_cmd="python \"$python_path\" --root \"$experiment_root\" tdf"
    if [ -n "$python_args" ]; then
        python_cmd="$python_cmd $python_args"
    fi
    eval "$python_cmd"
    
    if [ $? -ne 0 ]; then
        echo "  ✗ Failed: Python frontend for $python_file"
        return 1
    fi
    
    # Step 2: Run compile binary
    echo "  Step 2: Running compile backend..."
    local compile_cmd=(
        "$COMPILE_BIN"
        --sched_dfg
        --exe_folder "$exe_folder"
        --bootstrapping_precision 19
        --log_scale 45
        --log_chunk_size "$log_chunk_size"
    )
    
    # Only add usable_levels if it's not empty (some benchmarks don't use it)
    if [ -n "$usable_levels" ] && [ "$usable_levels" != "0" ]; then
        compile_cmd+=(--usable_levels "$usable_levels")
    fi
    
    "${compile_cmd[@]}"
    
    if [ $? -ne 0 ]; then
        echo "  ✗ Failed: Compile backend for $python_file"
        return 1
    fi
    
    # Step 3: Copy compiled files to output directory
    echo "  Step 3: Copying compiled files..."
    mkdir -p "$output_dir"
    
    # Copy the relevant files (adjust based on actual output structure)
    if [ -d "$exe_folder" ]; then
        cp -r "$exe_folder"/* "$output_dir/" 2>/dev/null || true
        # Also copy from experiment root if there are files there
        if [ -f "${experiment_root}/rt.df" ]; then
            cp "${experiment_root}/rt.df" "$output_dir/" 2>/dev/null || true
        fi
        if [ -d "${experiment_root}/ch_ir" ]; then
            cp -r "${experiment_root}/ch_ir" "$output_dir/" 2>/dev/null || true
        fi
        if [ -d "${experiment_root}/enc.cfg" ]; then
            cp -r "${experiment_root}/enc.cfg" "$output_dir/" 2>/dev/null || true
        fi
        echo "  ✓ Success: $output_dir"
    else
        echo "  ✗ Warning: Exe folder not found: $exe_folder"
        # Try to find alternative locations
        if [ -d "${experiment_root}/shared" ]; then
            echo "  Trying alternative location: ${experiment_root}/shared"
            cp -r "${experiment_root}/shared"/* "$output_dir/" 2>/dev/null || true
        fi
        return 1
    fi
}

# Determine which sizes to compile
if [ -n "$1" ]; then
    # Single size specified
    SIZES=("$1")
else
    # Default: compile with both 8192 and 32768
    SIZES=(8192 32768)
fi

# Check if compile binary exists
if [ ! -f "$COMPILE_BIN" ]; then
    echo "Error: Compile binary not found at $COMPILE_BIN"
    echo "Please set FHELIPE_DIR environment variable or ensure fhelipe is at ../fhelipe"
    exit 1
fi

# Compile all benchmarks with each size
for size in "${SIZES[@]}"; do
    echo ""
    echo "=== Compiling with size=$size ==="
    
    # Map benchmarks to their configurations
    # Format: python_file, benchmark_name, size, exe_folder_suffix, log_chunk_size, [usable_levels]
    # The exe_folder_suffix corresponds to the 'id' parameter in the Python class
    # Based on user examples and actual file structure
    
    # Matmul CT-CT benchmarks
    # matmul.py -> matmul_128_64 (n=64) for 8192, matmul_256_128 (n=128) for 32768
    if [ "$size" == "8192" ]; then
        # Uses id=(64) -> 64/shared
        compile_benchmark "matmul_ct_ct.py" "matmul_128_64" "$size" "64" "12"
    else
        # Uses id=(128) -> 128/shared
        compile_benchmark "matmul_ct_ct.py" "matmul_256_128" "$size" "128" "14"
    fi
    
    # Double matmul CT-CT
    # double_matmul_ctct.py -> different variants based on (n, m) parameters
    if [ "$size" == "8192" ]; then
        # Uses id=(64) -> 64/shared
        compile_benchmark "double_matmul_ct_ct.py" "double_matmul_128_64" "$size" "64" "12"
    else
        # Uses id=(128) -> 128/shared
        compile_benchmark "double_matmul_ct_ct.py" "double_matmul_256_128" "$size" "128" "14"
        # Also compile with id=(128, 64) -> 128_64/shared (based on example)
        compile_benchmark "double_matmul_ct_ct.py" "double_matmul_256_128" "$size" "128_64" "13"
    fi
    
    # Double matmul CT-PT (only for 8192 based on examples)
    if [ "$size" == "8192" ]; then
        # Uses id=(64) -> 64/shared
        compile_benchmark "double_matmul_ct_pt.py" "double_matmul_ct_pt" "$size" "64" "12"
    fi
    
    # Convolution (conv2d.py in examples, but we have conv.py)
    # Uses id=(32) -> 32/shared or just shared based on implementation
    # Note: conv.py has id=(32), so folder might be "32/shared"
    compile_benchmark "conv.py" "convolution" "$size" "32" "12"
    
    # Logreg (logreg.py in examples, but we have matvecmul.py which implements logreg)
    # Uses id=(32) -> 32/shared or just shared
    # Note: matvecmul.py has id=(32), so folder might be "32/shared" or just "shared"
    if [ "$size" == "8192" ]; then
        compile_benchmark "matvecmul.py" "logreg" "$size" "" "13"
    else
        compile_benchmark "matvecmul.py" "logreg" "$size" "" "15"
    fi
    
    # BERT attention (attention.py)
    # Note: User examples show bert.py for both matmul and attention
    # attention.py uses id=((n, m)) -> might be in shared or a subfolder
    if [ -f "${FHELIPE_DIR}/frontend/fheapps/rotom/attention.py" ]; then
        # For bert_matmul, might need a different file or parameters
        # For bert_attention, use attention.py
        compile_benchmark "attention.py" "bert" "$size" "" "13"
    fi
    
    # TTM - check if it exists in tensor apps directory
    if [ -f "${FHELIPE_DIR}/frontend/fheapps/tensor/ttm.py" ]; then
        local ttm_log_chunk=$([ "$size" == "8192" ] && echo "12" || echo "13")
        # TTM might be in a different location, adjust path if needed
        echo "  Note: TTM found in tensor apps, may need special handling"
    fi
done

echo ""
echo "=== Compilation complete ==="
echo "Output files are in: $OUTPUT_DIR"
echo ""
echo "Files compiled with size 8192 have no suffix."
echo "Files compiled with size 32768 have '_32768' suffix."
