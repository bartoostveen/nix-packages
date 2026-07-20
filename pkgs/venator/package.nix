{
  lib,
  buildGoModule,
  fetchFromGitea,
  go,
  mdbook,
  versionCheckHook,
  withDocs ? true,
}:

buildGoModule (finalAttrs: {
  pname = "venator";
  version = "0-unstable-2026-07-21";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "matrix-venator";
    repo = "venator";
    rev = "36446c80b7573873cc8ddce75d476ce724fe505a";
    hash = "sha256-+lpOE8wYTprvBQX6Hz5UP1veDZ8/P+bitJrXMzcKcFU=";
  };

  vendorHash = "sha256-1k27rRrE5dohKLi+72VoglbvDN2KJkOOFMknUBqAMhY=";

  preBuild = lib.optionalString withDocs ''
    if [ -d vendor ]; then
      go generate -tags "$VENATOR_BUILD_TAGS" ./internal/embedded_docs/
    fi
  '';

  nativeBuildInputs = lib.optional withDocs mdbook ++ [
    versionCheckHook
  ];

  tags = lib.optional withDocs "docs";

  env = {
    VENATOR_BUILD_TAGS = lib.concatStringsSep "," finalAttrs.tags;
    GOEXPERIMENT = "jsonv2";
  };

  ldflags = [
    "-s"
    "-w"
    "-X"
    "codeberg.org/timedout/venator/version.LatestTag=${finalAttrs.version}"
    "-X"
    "codeberg.org/timedout/venator/version.CurrentTag=${finalAttrs.version}"
    "-X"
    "codeberg.org/timedout/venator/version.CommitHash=${finalAttrs.src.rev}"
    "-X"
    "codeberg.org/timedout/venator/version.Dirty=false"
    "-X"
    "codeberg.org/timedout/venator/version.BuildDate=\"1970.01.01T00.00.00Z\""
    "-X"
    "codeberg.org/timedout/venator/version.GoVersion=${go.version}"
    "-X"
    "codeberg.org/timedout/venator/version.OSArch=${finalAttrs.goModules.GOARCH}"
  ];

  meta = {
    description = "Matrix Venator - versatile capital Matrix homeserver written from scratch in mautrix-go";
    homepage = "https://codeberg.org/timedout/venator";
    license = lib.licenses.mpl20;
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "venatorctl";
  };
})
