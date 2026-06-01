# SlicedLabs OS — home-manager module (the "Declare" rung; config layer only).
#
# Imperative concerns — packages, systemd system units, AUR (quickshell/swaylock),
# the hash-chained Warden ledger — stay with bootstrap.sh, which is the source of
# truth for provisioning. This module declares the *config layer* + session env so a
# home-manager host can adopt the SlicedLabs desktop config declaratively. It links
# to a live dotfiles checkout (mkOutOfStoreSymlink) so the render-* cascade keeps
# working; a fuller port (generating configs in the Nix store) is a future step.
{ config, lib, pkgs, ... }:
let
  cfg = config.slicedlabs;
in {
  options.slicedlabs = {
    enable = lib.mkEnableOption "the SlicedLabs OS config layer";
    dotfiles = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.dotfiles";
      description = "Path to the SlicedLabs dotfiles checkout (token SSOT + rendered configs).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Session markers the stack reads (per-workspace hue is set at spawn by scene.sh).
    home.sessionVariables = {
      SLICEDLABS_OS = "1";
      EDITOR = "nvim";
    };

    # Declare the config layer by linking the repo's stow targets — the declarative
    # equivalent of `stow` for a home-manager host (keeps the .tmpl → render-* cascade).
    xdg.configFile = lib.genAttrs
      [ "niri" "ghostty" "zellij" "mako" "fish" "quickshell" ]
      (name: {
        source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfiles}/${name}/.config/${name}";
      });

    home.packages = with pkgs; [ jq ]; # minimal; the full stack is bootstrap.sh's job
  };
}
