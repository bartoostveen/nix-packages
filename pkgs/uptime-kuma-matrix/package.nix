{
  lib,
  buildGoModule,
  fetchgit,
  nix-update-script,
}:

buildGoModule (_finalAttrs: {
  pname = "uptime-kuma-matrix";
  version = "0-unstable-2026-07-27";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchgit {
    url = "https://forge.koenoostveen.nl/koen/uptimekuma-matrix.git";
    rev = "80591c0d9e3d765a38d48b31ddc463907ef7b08f";
    hash = "sha256-jaErUdHuJbykbU+/415iud5vYoEdX9oFTBqYDNbIMDw=";
  };

  vendorHash = "sha256-w/ZmNmM9MKnn9UN++ZvVfroRW8KMJHiZddJU0R8gcBE=";

  ldflags = [ "-s" ];

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "Very simple UptimeKuma webhook receiver for Matrix written in Go";
    homepage = "https://forge.koenoostveen.nl/koen/uptimekuma-matrix.git";
    license = [ ];
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "uptimekuma-matrix";
    platforms = lib.platforms.all;
  };
})
