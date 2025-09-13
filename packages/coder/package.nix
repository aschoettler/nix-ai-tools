{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  gcc-unwrapped,
}:

let
  version = "0.2.142";

  sources = {
    x86_64-linux = {
      url = "https://github.com/just-every/code/releases/download/v${version}/code-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-DsPrRltA5mXlwqRwDcBT5SKTMjwZDQm7wlZUjkmiYdU=";
    };
    aarch64-linux = {
      url = "https://github.com/just-every/code/releases/download/v${version}/code-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-AWkRxmtXyKVhh3J6+u7xgsP52WGhEXYxp2A5MTKFbm4=";
    };
    x86_64-darwin = {
      url = "https://github.com/just-every/code/releases/download/v${version}/code-x86_64-apple-darwin.tar.gz";
      hash = "sha256-owAF0OKlOYQxakoQZgnjfPug8YMs8ca/AlN/bgX1NHA=";
    };
    aarch64-darwin = {
      url = "https://github.com/just-every/code/releases/download/v${version}/code-aarch64-apple-darwin.tar.gz";
      hash = "sha256-2hGcktuMtOFxmh5q/zAGzLajxLjpAb+isU2uytk4OpI=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "coder";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.isLinux [ gcc-unwrapped.lib ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    # The tarball contains a single executable named like
    #   code-<target-triple>
    # Install it as `coder` to avoid collision with other tools named `code`.
    src_bin=$(echo code-*)
    if [ -z "$src_bin" ] || [ ! -e "$src_bin" ]; then
      echo "Could not find code-* in $PWD" >&2
      ls -la >&2 || true
      exit 1
    fi
    install -D -m755 "$src_bin" "$out/bin/coder"

    runHook postInstall
  '';

  passthru = {
    updateScript = ./update.sh;
  };

  meta = with lib; {
    description = "Just Every Code CLI (fork of OpenAI Codex) - a coding agent that runs locally";
    homepage = "https://github.com/just-every/code";
    downloadPage = "https://github.com/just-every/code/releases";
    changelog = "https://github.com/just-every/code/releases/tag/v${version}";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    maintainers = with maintainers; [ ];
    mainProgram = "coder";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
