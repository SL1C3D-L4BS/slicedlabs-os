function with-vulkan --description 'Run a command pinned to the Vulkan backend (already default)'
    set -lx OLLAMA_LLM_LIBRARY vulkan
    set -lx OLLAMA_VULKAN 1
    # Strip ROCm from LD_LIBRARY_PATH to avoid backend confusion in some libs.
    if set -q LD_LIBRARY_PATH
        set -lx LD_LIBRARY_PATH (string replace -r '/opt/rocm/[^:]*:?' '' -- $LD_LIBRARY_PATH)
    end
    if test -z "$argv"
        echo "with-vulkan: usage: with-vulkan <cmd> [args...]" >&2
        return 2
    end
    command $argv
end
