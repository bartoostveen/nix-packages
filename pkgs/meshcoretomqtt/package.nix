{
  lib,
  python3Packages,
  fetchFromGitHub,
  nix-update-script,
  ed25519-orlp,
  makeWrapper,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "meshcoretomqtt";
  version = "0-unstable-2026-07-16";

  format = "other";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "Cisien";
    repo = "meshcoretomqtt";
    rev = "0cb527f3bb580aa02653aa3e8122ac4cf1929a09";
    hash = "sha256-jeXqA24sYTuDhPJHl05PuKD9TvhMi/Bju9zVXCv4d7M=";
  };

  build-system = [
    python3Packages.setuptools
  ];

  dependencies = with python3Packages; [
    ed25519-orlp
    paho-mqtt
    pyserial
    tomli
  ];

  optional-dependencies = with python3Packages; {
    test = [
      pytest
    ];
  };

  pythonImportsCheck = [
    "mctomqtt"
  ];

  nativeInstallInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/{bin,${python3Packages.python.sitePackages}}
    mkdir -p $out/${python3Packages.python.sitePackages}/bridge

    install -Dm644 config_loader.py $out/${python3Packages.python.sitePackages}/config_loader.py
    install -Dm755 auth_token.py $out/${python3Packages.python.sitePackages}/auth_token.py
    install -Dm755 mctomqtt.py $out/${python3Packages.python.sitePackages}/mctomqtt.py

    cp bridge/*.py $out/${python3Packages.python.sitePackages}/bridge/

    makeWrapper ${python3Packages.python.interpreter} $out/bin/mctomqtt \
      --add-flags "$out/${python3Packages.python.sitePackages}/mctomqtt.py" \
      --set PYTHONPATH "$out/${python3Packages.python.sitePackages}:${
        python3Packages.python.withPackages (
          ps: with ps; [
            paho-mqtt
            pyserial
          ]
        )
      }/${python3Packages.python.sitePackages}:${ed25519-orlp}/${python3Packages.python.sitePackages}"
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "A python based script to send meshore debug and packet capture data to MQTT for analysis  Requires meshcore repeater to be connected to a raspberry pi, server or similar linux device able to run python";
    homepage = "https://github.com/Cisien/meshcoretomqtt";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "meshcoretomqtt";
  };
})
