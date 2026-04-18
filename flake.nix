{
  description = "Nix flake for OpenClaw — multi-channel AI gateway CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = {
          openclaw = pkgs.callPackage ./pkgs/openclaw { };
          default = self.packages.${system}.openclaw;
        };

        apps.openclaw = {
          type = "app";
          program = "${self.packages.${system}.openclaw}/bin/openclaw";
          meta = self.packages.${system}.openclaw.meta;
        };

        checks.build = self.packages.${system}.openclaw;
      }
    ) // {
      overlays.default = final: prev: {
        openclaw = final.callPackage ./pkgs/openclaw { };
      };
    };
}
