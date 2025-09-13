{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  nodejs_20,
}:

let
  # Track upstream GitHub releases (>= 0.4.0)
  version = "0.5.0-preview-2";

  source = {
    url = "https://github.com/google-gemini/gemini-cli/releases/download/v${version}/gemini.js";
    # Placeholder; run update.sh to refresh
    hash = "sha256-z3ROpOZ+7C+xjQ53dWRcOSwaw8sUZRyv1M9ejQ3mFSQ=";
  };
in
stdenv.mkDerivation {
  pname = "gemini-cli";
  inherit version;

  src = fetchurl { inherit (source) url hash; };

  nativeBuildInputs = [ makeWrapper ];
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -D -m644 "$src" "$out/libexec/gemini-cli/gemini.js"
    makeWrapper "${nodejs_20}/bin/node" "$out/bin/gemini" \
      --add-flags "$out/libexec/gemini-cli/gemini.js"

    runHook postInstall
  '';

  passthru = {
    updateScript = ./update.sh;
  };

  meta = {
    description = "AI agent that brings the power of Gemini directly into your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    changelog = "https://github.com/google-gemini/gemini-cli/releases";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    maintainers = with lib.maintainers; [ donteatoreo ];
    platforms = lib.platforms.all;
    mainProgram = "gemini";
  };
}
