function with-rocm --description 'Run a command with the ROCm backend active'
    # ROCm env is already exported globally; this function explicitly opts in
    # by also setting OLLAMA_LLM_LIBRARY=rocm + LD_LIBRARY_PATH adjustments
    # the ROCm runtime sometimes needs.
    set -lx OLLAMA_LLM_LIBRARY rocm
    set -lx GGML_HIP_NO_PINNED 1
    set -lx LD_LIBRARY_PATH /opt/rocm/lib:$LD_LIBRARY_PATH
    if test -z "$argv"
        echo "with-rocm: usage: with-rocm <cmd> [args...]" >&2
        return 2
    end
    command $argv
end
