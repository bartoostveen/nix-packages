{
  lib,
  buildGoModule,
  fetchFromGitLab,
  nix-update-script,
}:

buildGoModule (finalAttrs: {
  pname = "alertmanager-matrix";
  version = "0.5.0";

  src = fetchFromGitLab {
    owner = "slxh";
    repo = "matrix/alertmanager_matrix";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/rnsuFaiMEHv19Wd0rHngpmmQk1Ka07gxu7luJa0emQ=";
  };

  patches = [
    ./0001-fix-proper-color-handing-according-to-spec.patch
  ];

  vendorHash = "sha256-10CKNQ0mCa+k3aFQH/5XvG5LYGyU/gm+kr2eYmqU6AU=";

  ldflags = [ "-s" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Service for managing and receiving Alertmanager alerts on Matrix";
    homepage = "https://github.com/silkeh/alertmanager_matrix";
    license = lib.licenses.eupl12;
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "alertmanager_matrix";
    platforms = lib.platforms.linux;
  };
})
