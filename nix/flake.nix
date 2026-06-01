{
  description = "SlicedLabs OS — the declarative config-layer seed (home-manager module + dev shell)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      # The "Declare" rung: a home-manager module for the SlicedLabs config layer.
      # Imperative concerns (packages, system units, AUR, the Warden ledger) stay with
      # bootstrap.sh; this declares the rendered config + session layer. See ./home.nix.
      homeManagerModules.slicedlabs = import ./home.nix;

      # `nix develop` — everything to work on the cascade (renderers, gates, ISO build).
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          python313 uv ruff basedpyright
          stow git gitleaks just
          archiso          # iso/build.sh (the Try rung)
          jq typst         # generators + keyboard poster
        ];
        shellHook = ''
          echo "SlicedLabs OS dev shell — render-*, verify-all, iso/build.sh"
        '';
      };
    };
}
