{
  system ? builtins.currentSystem,
  pkgs ? import <nixpkgs> { inherit system; },
  ...
}:

let
  inherit (pkgs)
    lib
    callPackage
    newScope
    ;

  inherit (lib)
    id
    packagesFromDirectoryRecursive
    warn
    ;

  conf = if pkgs ? _bartPackages then pkgs._bartPackages else { };

  suppressSystemWarning = if conf ? suppressSystemWarning then conf.suppressSystemWarning else false;
  prefix = if conf ? prefix then conf.prefix else null;

  packages = packagesFromDirectoryRecursive {
    directory = ./pkgs;
    inherit callPackage newScope;
  };

  packagesWithWarning =
    (
      if system == "x86_64-linux" || suppressSystemWarning then
        id
      else
        warn ''
          https://git.bartoostveen.nl/bart/nix-packages.git

          You are on ${system}. Only x86_64-linux builds are tested.
          You may need to adjust packages in order to make them work on another platform.

          Contributions welcome!
          Suppress this warning by:

            1) when using nix-env:  importing the packages with with the overlay:
                                    "(_final: _prev: { _bartPackages.suppressSystemWarning = true; })"

                                    See also: https://git.bartoostveen.nl/bart/nix-packages#configuration
            2) when using flakes:   using the overlay:
                                      overlays = [
                                        inputs.bart-packages.overlays.suppressSystemWarning
                                        inputs.bart-packages.overlays.default
                                      ];
        ''
    )
      packages;
in
(if prefix == null then packagesWithWarning else { ${prefix} = packagesWithWarning; })
