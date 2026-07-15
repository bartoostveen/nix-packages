{
  system ? builtins.currentSystem,
  pkgs ? import <nixpkgs> { inherit system; },
  suppressSystemWarning ?
    if pkgs ? _bartPackages.suppressSystemWarning then
      pkgs._bartPackages.suppressSystemWarning
    else
      false,
  prefix ? if pkgs ? _bartPackages.prefix then pkgs._bartPackages.prefix else null,
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

            1a) when using nix-env: importing the packages with "suppressSystemWarning = true;"
            1b)                     dito, with the overlay: "(_final: _prev: { _bartPackages.suppressSystemWarning = true; })"
            2 ) when using flakes:  using the overlay:
                                      overlays = [
                                        inputs.bart-packages.overlays.default
                                        inputs.bart-packages.overlays.suppressSystemWarning
                                      ];
        ''
    )
      packages;
in
(if prefix == null then packagesWithWarning else { ${prefix} = packagesWithWarning; })
