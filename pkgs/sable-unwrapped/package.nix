{
  lib,
  stdenv,
  nix-update-script,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_10,
  pnpmConfigHook,
  nodejs_24,
}:

let
  pnpm = pnpm_10;
  nodejs = nodejs_24;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "sable-unwrapped";
  version = "1.21.0-unstable-2026-08-04";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "SableClient";
    repo = "Sable";
    rev = "8093b2e571d6be2f8b84887a0f715b4adf3fab16";
    hash = "sha256-GmopT4dRhcyBhlutHHz+mkzG0JE4RniFKENDgg0bATY=";
  };

  nativeBuildInputs = [
    pnpm
    pnpmConfigHook
    nodejs
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-3jfiIjSoXFN4vtp84FZ3ZhvIoI7YVw31Larmsa96Tzc=";
  };

  env = {
    VITE_BUILD_HASH = finalAttrs.src.rev;
    SABLE_BUILD_FLAVOR = "stable";
  };

  buildPhase = ''
    runHook preBuild

    pnpm build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -r dist $out

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "An almost stable Matrix client";
    homepage = "https://github.com/SableClient/Sable";
    changelog = "https://github.com/SableClient/Sable/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ bartoostveen ];
    platforms = lib.platforms.all;
  };
})
