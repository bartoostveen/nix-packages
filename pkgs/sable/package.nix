{
  callPackage,
  stdenv,
  unwrapped ? callPackage ./unwrapped.nix { },
  conf ? { },
}:

if (conf == { }) then
  unwrapped
else
  stdenv.mkDerivation {
    pname = "${unwrapped.pname}-wrapped";
    inherit (unwrapped) version meta;

    passthru = { inherit conf; };

    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      ln -s ${unwrapped}/* $out
      rm $out/config.json
      cp ${builtins.toFile "sable-config.json" (builtins.toJSON conf)} $out/config.json
    '';
  }
