{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  nix-update-script,
  autoconf,
  ensureNewerSourcesForZipFilesHook,
  gnumake,
  jdk21,
  perl,
  pkg-config,
  unzip,
  zip,
  zlib,
  alsa-lib,
  cpio,
  cups,
  file,
  fontconfig,
  freetype,
  giflib,
  libjpeg,
  libx11,
  libxext,
  libxrandr,
  libxrender,
  libxi,
  libxinerama,
  libxt,
  libxtst,
  jre-generate-cacerts,
  cacert,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openjml";
  version = "21.0.29";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "OpenJML";
    repo = "OpenJML";
    tag = finalAttrs.version;
    hash = "sha256-A0gSiV45GSi0eSXcY5FDN1c6iSLHVkp4Y/MnqEaiGgU=";
  };

  sourceRoot = "workspace";

  unpackPhase = ''
    runHook preUnpack

    mkdir -p workspace

    cp -r ${finalAttrs.src} workspace/OpenJML
    cp -r ${finalAttrs.passthru.specs} workspace/Specs
    cp -r ${finalAttrs.passthru.annotations} workspace/JMLAnnotations
    cp -r ${finalAttrs.passthru.solvers} workspace/Solvers
    cp -r ${finalAttrs.passthru.demo} workspace/OpenJMLDemo
    cp -r ${finalAttrs.passthru.documentation} workspace/openjml.github.io

    mkdir -p workspace/OpenJMLlsp/libs
    cp ${finalAttrs.passthru.lsp4j} workspace/OpenJMLlsp/libs/org.eclipse.lsp4j-1.0.0.jar
    cp ${finalAttrs.passthru.lsp4j-jsonrpc} workspace/OpenJMLlsp/libs/org.eclipse.lsp4j.jsonrpc-1.0.0.jar

    chmod -R u+w workspace

    runHook postUnpack
  '';

  postPatch = ''
    patchShebangs OpenJML/OpenJMLsrc
    patchShebangs OpenJML/OpenJMLlsp

    cat >> OpenJML/OpenJMLsrc/Makefile <<'EOF'

    .FORCE:
    EOF

    substituteInPlace OpenJML/OpenJMLsrc/Makefile \
      --replace-fail ".PHONY:" \
      ".PHONY: .FORCE" \
      --replace-fail '$(MAKE) openjml-lsp' \
      "" \
      --replace-fail '@cp build/*/jdk/modules/java.base/org/jmlspecs/runtime/*.class $(TEMPLIB)/org/jmlspecs/runtime' \
      'cp -r ../../JMLAnnotations/src/org/jmlspecs/annotation $(TEMPLIB)/org/jmlspecs/ \
      && cp -r ../../Specs/specs/org/jmlspecs/runtime $(TEMPLIB)/org/jmlspecs/ \
      && ${jdk21}/bin/javac -d $(TEMPLIB) $$(find $(TEMPLIB)/org/jmlspecs -name "*.java")' \
      --replace-fail '@cp build/*/jdk/modules/java.base/org/jmlspecs/annotation/*.class $(TEMPLIB)/org/jmlspecs/annotation' \
      "" \
      --replace-fail 'f=$$(echo build/*release/jdk/release);' \
      'for d in build/*release/jdk/release build/*release/images/jdk/release; do if [ -f \"\$d\" ]; then f=\"\$d\"; break; fi; done;'

    substituteInPlace OpenJML/OpenJMLlsp/Makefile \
      --replace-fail "curl" "true # "
  '';

  nativeBuildInputs = [
    autoconf
    ensureNewerSourcesForZipFilesHook
    gnumake
    jdk21
    perl
    pkg-config
    unzip
    zip
    zlib
  ];

  buildInputs = [
    alsa-lib
    cpio
    file
    cups
    fontconfig
    freetype
    giflib
    libjpeg
    libx11
    libxext
    libxrandr
    libxrender
    libxi
    libxinerama
    libxt
    libxtst
  ];

  configureFlags = [
    "READELF=${stdenv.cc.targetPrefix}readelf"
    "AR=${stdenv.cc.targetPrefix}ar"
    "STRIP=${stdenv.cc.targetPrefix}strip"
    "NM=${stdenv.cc.targetPrefix}nm"
    "OBJDUMP=${stdenv.cc.targetPrefix}objdump"
    "OBJCOPY=${stdenv.cc.targetPrefix}objcopy"
    "--with-boot-jdk=${jdk21.home}"
    "--enable-unlimited-crypto"
    "--with-native-debug-symbols=internal"
    "--with-stdc++lib=dynamic"
    "--with-zlib=system"
    "--with-giflib=system"
  ];

  preConfigure = ''
    pushd OpenJML/OpenJMLsrc
    configureFlags+=("--with-jobs=''${NIX_BUILD_CORES}")

    mkdir "$NIX_BUILD_TOP/cacerts-gen"
    pushd "$NIX_BUILD_TOP/cacerts-gen"
    JAVA_TOOL_OPTIONS="-Dkeystore.pkcs12.certProtectionAlgorithm=NONE -Dkeystore.pkcs12.macAlgorithm=NONE" \
      ${jre-generate-cacerts} ${jdk21.home}/bin/keytool ${cacert}/etc/ssl/certs/ca-bundle.crt
    popd
    configureFlags+=("--with-cacerts-file=$NIX_BUILD_TOP/cacerts-gen/cacerts")
  '';

  makeFlags = [ "release" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    unzip release-temp/openjml.zip -d $out

    runHook postInstall
  '';

  env = {
    NIX_CFLAGS_COMPILE = "-Wno-error";

    NIX_LDFLAGS = lib.concatStringsSep " " [
      "-lfontconfig"
      "-lcups"
      "-lXinerama"
      "-lXrandr"
      "-lmagic"
    ];
  };

  doCheck = false;
  doInstallCheck = false;

  passthru = {
    updateScript = nix-update-script { };
    specs = fetchFromGitHub {
      owner = "OpenJML";
      repo = "Specs";
      tag = "V21-0.9";
      hash = "sha256-ZN0QJHwQ4NJlwwg8fIhyolTa5wv8Bv6O/VCI8v9+ugk=";
    };
    demo = fetchFromGitHub {
      owner = "OpenJML";
      repo = "OpenJMLDemo";
      tag = "release/0.8.59";
      hash = "sha256-F3bmuqjdOe+Tz/LBAvSxS23dlvBuKxWAPcyw3TUhNF8=";
    };
    solvers = fetchFromGitHub {
      owner = "smtlib";
      repo = "Solvers";
      tag = "z3-4.9.1-20260523-195605";
      hash = "sha256-C6Oh27zKXEsB0twP4OgHQuanaTHBV4YSPfVDbOpRrzE=";
    };
    annotations = fetchFromGitHub {
      owner = "OpenJML";
      repo = "JMLAnnotations";
      tag = "release/0.8.59";
      hash = "sha256-ZPU8VnqyGwYq7CQgTqPVTW56hKPFVVp4mlnLzKYPj6Q=";
    };
    documentation = fetchFromGitHub {
      owner = "OpenJML";
      repo = "openjml.github.io";
      rev = "20f2f42fa6de9e431ea89668a6b612018d91b1ce";
      hash = "sha256-11lXquz8LNsAOj5W2v5KYhbLA6jpoEgObO78ECB6x9A=";
    };
    lsp4j = fetchurl {
      url = "https://repo1.maven.org/maven2/org/eclipse/lsp4j/org.eclipse.lsp4j/1.0.0/org.eclipse.lsp4j-1.0.0.jar";
      hash = "sha256-zNeIk/rMa/zDWdVsugXT1bhetB5MQNS0IVykXbX0Ftk=";
    };
    lsp4j-jsonrpc = fetchurl {
      url = "https://repo1.maven.org/maven2/org/eclipse/lsp4j/org.eclipse.lsp4j.jsonrpc/1.0.0/org.eclipse.lsp4j.jsonrpc-1.0.0.jar";
      hash = "sha256-lkf+sFJL92PIeOEquHimhBArgczLP3f+7L7HCdVPm7s=";
    };
  };

  meta = {
    description = "This is the primary repository for the source code of the OpenJML project. The source code is licensed under GPLv2 because it derives from OpenJDK which is so licensed. The active issues list for OpenJML development is here and the wiki contains information relevant to development. Public documentation for users is at the project website";
    homepage = "https://github.com/OpenJML/OpenJML";
    changelog = "https://github.com/OpenJML/OpenJML/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "openjml";
    platforms = lib.platforms.all;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode
    ];
  };
})
