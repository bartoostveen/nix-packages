{
  description = "Personal packages that are not in nixpkgs because they can't/won't be upstreamed";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      flake.overlays = {
        default =
          _: prev:
          import ./default.nix {
            system = prev.stdenv.system;
            pkgs = prev;
          };
        suppressSystemWarning = _: _: { _bartPackages.suppressSystemWarning = true; };
      };

      flake = {
        hydraJobs = inputs.self.legacyPackages.x86_64-linux;
      };

      perSystem =
        {
          pkgs,
          system,
          lib,
          ...
        }:

        let
          inherit (lib) filterAttrs isDerivation;

          packages = pkgs.callPackage ./default.nix { };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [
                "olm-3.2.16"
              ];
            };
          };

          treefmt = {
            programs.nixfmt.enable = true;
            programs.deadnix.enable = true;
          };

          packages = filterAttrs (_: isDerivation) packages;
          legacyPackages = packages;
        };
    };
}
