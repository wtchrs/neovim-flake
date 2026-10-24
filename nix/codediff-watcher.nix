{ pkgs, lib }:

let
  # Keep this aligned with codediff.core.installer.watcher.VERSION.
  version = "0.23.2";
  bundles = {
    x86_64-linux = {
      arch = "x64";
      hash = "sha256-acXsKVZCUZ952p57kIkK0TLw/YDiiD9v9pZxBqAF27w=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-7UYUvuNtuCl/tFqBFV9VuSqc7MQi2qqJf+KKzJf+OQU=";
    };
  };
  bundle = bundles.${pkgs.stdenv.hostPlatform.system};
in
pkgs.stdenv.mkDerivation {
  pname = "codediff-watcher";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/esmuellert/codediff/releases/download/v${version}/codediff-watcher-${version}-linux-${bundle.arch}.tar.gz";
    inherit (bundle) hash;
  };

  sourceRoot = ".";
  nativeBuildInputs = [ pkgs.autoPatchelfHook ];
  buildInputs = [ pkgs.stdenv.cc.cc.lib ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 codediff-watcher "$out/bin/codediff-watcher"
    runHook postInstall
  '';

  meta = {
    description = "Native filesystem watcher for codediff.nvim";
    homepage = "https://github.com/esmuellert/codediff";
    license = lib.licenses.mit;
    platforms = builtins.attrNames bundles;
    mainProgram = "codediff-watcher";
  };
}
