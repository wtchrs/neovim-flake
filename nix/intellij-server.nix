{ pkgs, lib }:

let
  version = "263.6379.0";
  bundles = {
    x86_64-linux = {
      suffix = "";
      hash = "sha256-dSnMcz1KAg4cE2kYOy9g4TXIW48HS78n0UdqWns4OcM=";
    };
    aarch64-linux = {
      suffix = "-aarch64";
      hash = "sha256-e1CvotbwjL2dw5zNm/icA7s3/yVuJSQ/winPjsEDVOo=";
    };
  };
  bundle = bundles.${pkgs.stdenv.hostPlatform.system};
in
pkgs.stdenv.mkDerivation {
  pname = "intellij-server";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://download.jetbrains.com/language-server/intellij-server/${version}/intellij-server-${version}${bundle.suffix}.tar.gz";
    inherit (bundle) hash;
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];
  buildInputs = with pkgs; [
    stdenv.cc.cc
    zlib
    alsa-lib
    cups
    fontconfig
    libx11
    libxext
    libxi
    libxrender
    libxtst
    libxrandr
  ];

  # Allow absent Wayland dependencies in the headless server's bundled JBR.
  autoPatchelfIgnoreMissingDeps = [
    "libwayland-client.so.0"
    "libwayland-cursor.so.0"
    "libxkbcommon.so.0"
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/intellij-server" "$out/bin"
    cp -a . "$out/share/intellij-server/"
    ln -s "$out/share/intellij-server/bin/intellij-server" "$out/bin/intellij-server"
    runHook postInstall
  '';

  meta = {
    description = "IntelliJ-powered Java and Kotlin language server";
    homepage = "https://www.jetbrains.com/help/intellij-vscode/About-instance.html";
    license = lib.licenses.unfree;
    platforms = builtins.attrNames bundles;
    mainProgram = "intellij-server";
  };
}
