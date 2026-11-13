## Supported Platforms

- `x86_64-linux` | `nixos-unstable`

## Installation

**Step 1: Add this to you `flake.nix` inputs** 

```nix
ytm-rs = {
  url = "github:imrayy/ytm-rs-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**Step 2: Add it to your packages**

```nix
environment.systemPackages = [
  inputs.ytm-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
];
```
