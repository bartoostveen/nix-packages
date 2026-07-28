{
  stdenv,
  sable,
  sable-unwrapped,
  conf ? { },
}:

stdenv.mkDerivation {
  pname = "sable";
  inherit (sable-unwrapped) version meta;

  passthru = {
    inherit conf;
    withGifSupport = sable.override {
      conf.gifs = {
        proxyUrl = "gifs.sable.moe";
        klipyApiKey = "IfeIBlDMvq0av2BcKPDuxwRqbnYRbS90yNqFHEkK2Ja207tkR5nssh3NIlJRCr76";
      };
    };
  };

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    ln -s ${sable-unwrapped}/* $out
    rm $out/config.json
    cp ${builtins.toFile "sable-config.json" (builtins.toJSON conf)} $out/config.json
  '';
}
