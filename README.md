# openclaw-nix

Nix flake that packages [OpenClaw](https://github.com/openclaw/openclaw) from the npm registry.

**Motivation:** nixpkgs marks openclaw as insecure; this repo tracks the latest upstream release directly from npm.

## Usage as a flake input

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    openclaw.url = "github:stslex/openclaw-nix";
    openclaw.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, openclaw, ... }: {
    # Use the overlay in a NixOS module
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [ openclaw.overlays.default ];
          environment.systemPackages = [ pkgs.openclaw ];
        }
      ];
    };
  };
}
```

## Quick run

```bash
nix run github:stslex/openclaw-nix -- --version
```

## Manual update

```bash
# Update to latest npm release
./scripts/update.sh

# Pin a specific version
./scripts/update.sh 2026.5.1
```

## Auto-update

See `.github/workflows/update.yml` — added in a follow-up commit.

## Acknowledgements

Inspired by [stslex/claude-code-flake](https://github.com/stslex/claude-code-flake).
