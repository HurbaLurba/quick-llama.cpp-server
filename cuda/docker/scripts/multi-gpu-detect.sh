#!/bin/bash

# Multi-GPU Detection and Configuration Utility
# Returns tensor-split ratios for multi-GPU setups with 32GB+ total VRAM

detect_multi_gpu() {
    local split_flags=()
    
    if command -v nvidia-smi >/dev/null 2>&1; then
        mapfile -t gpu_mems < <(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | sed 's/ //g')
        local gpu_count=${#gpu_mems[@]}
        
        if [ "$gpu_count" -gt 1 ]; then
            local total_mem=0
            for m in "${gpu_mems[@]}"; do 
                total_mem=$((total_mem + m))
            done
            
            if [ "$total_mem" -ge 32768 ]; then
                local tensor_split=$(python -c "
import sys
total = $total_mem
mems = [$(IFS=,; echo "${gpu_mems[*]}")]
if total > 0 and mems:
    ratios = [m/total for m in mems]
    print(','.join(f'{r:.4f}' for r in ratios))
")
                if [ -n "$tensor_split" ]; then
                    split_flags+=("--split-mode" "row" "--tensor-split" "$tensor_split")
                    echo "🧩 Multi-GPU detected ($gpu_count GPUs, total ${total_mem}MiB). Using split-mode=row, tensor-split=$tensor_split" >&2
                fi
            else
                echo "ℹ️ Multi-GPU detected but total VRAM (${total_mem}MiB) < 32GB threshold. Using single GPU." >&2
            fi
        else
            echo "ℹ️ Single GPU detected." >&2
        fi
    else
        echo "⚠️ nvidia-smi not available. Skipping multi-GPU detection." >&2
    fi
    
    # Output the flags (space-separated)
    echo "${split_flags[@]}"
}

# If script is called directly, run the detection
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_multi_gpu
fi
