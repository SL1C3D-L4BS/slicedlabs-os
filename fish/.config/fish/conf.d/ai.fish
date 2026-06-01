# ai.fish — local AI environment (Phase H)
#
# Default backend is Vulkan (stable on Polaris). ROCm is installed alongside
# and gated behind `with-rocm <cmd>` or `systemctl --user start ollama-rocm`.
# CPU fallback always works.

# === slicedlabs (extracted to ~/Projects/slicedlabs) ===
# The package now resolves its team registry from $SLICEDLABS_CONFIG first, so
# the workstation keeps using the dotfiles team.toml (the SSOT) rather than the
# bundled default that ships with the standalone repo.
set -gx SLICEDLABS_CONFIG $HOME/.dotfiles/sliced-engine/.config/sliced-engine/team.toml

# === Vulkan (primary) ===
set -gx GGML_VK_VISIBLE_DEVICES 0
set -gx OLLAMA_LLM_LIBRARY vulkan
set -gx OLLAMA_VULKAN 1
set -gx OLLAMA_HOST 127.0.0.1:11434
set -gx OLLAMA_NUM_GPU 1
set -gx OLLAMA_GPU_OVERHEAD 0

# === ROCm (fallback, only used inside `with-rocm`) ===
# HSA_OVERRIDE_GFX_VERSION makes ROCm think Polaris (gfx803) is a supported
# RDNA1-like target. Memory `engine-platform-project` notes this works.
set -gx HSA_OVERRIDE_GFX_VERSION 8.0.3
set -gx ROCM_PATH /opt/rocm
set -gx HIP_VISIBLE_DEVICES 0
if test -d /opt/rocm/bin
    fish_add_path /opt/rocm/bin
end

# === Cloud LLM keys ===
# Loaded from ~/.config/ai/keys.env (rendered from .sops by `render-secrets`).
# Aider/Continue/slicedlabs gracefully fall back to local-Ollama when empty.
if test -f $HOME/.config/ai/keys.env
    while read -l line
        if string match -q "*=*" -- "$line"; and not string match -q "#*" -- "$line"
            set -gx (string split -m 1 = -- "$line")
        end
    end < $HOME/.config/ai/keys.env
end

# === Mem0 + Langfuse hosts (local first) ===
set -gx MEM0_HOST     http://localhost:8089
set -gx LANGFUSE_HOST http://localhost:3030
