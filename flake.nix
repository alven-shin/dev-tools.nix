{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        packages.jdtls = pkgs.stdenv.mkDerivation rec {
          pname = "jdtls";
          version = "1.33.0";
          timestamp = "202402151717";

          src = pkgs.fetchurl {
            url = "https://download.eclipse.org/jdtls/milestones/${version}/jdt-language-server-${version}-${timestamp}.tar.gz";
            sha256 = "sha256-UZQQl3lFPmN6Azglf97xevwA6OehO/2bSM0bg93z8YY=";
          };

          nativeBuildInputs = with pkgs; [makeWrapper];

          buildPhase = ''
            mkdir -p jdt-language-server
            tar xfz $src -C jdt-language-server
          '';

          installPhase = ''
            mkdir -p $out/bin $out/libexec
            cp -a jdt-language-server $out/libexec
            makeWrapper $out/libexec/jdt-language-server/bin/jdtls $out/bin/jdtls \
              --set PATH ${pkgs.lib.makeBinPath [pkgs.jdk17_headless pkgs.python3Minimal]}
          '';

          dontUnpack = true;
          dontPatch = true;
          dontConfigure = true;
        };

        packages.junit = pkgs.stdenv.mkDerivation rec {
          pname = "junit";
          version = "1.10.2";

          jar = pkgs.fetchurl {
            url = "https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/${version}/junit-platform-console-standalone-${version}.jar";
            sha512 = "sha512-YXVB4mWwDGQuWwscX2ytuHjthNDvNE2Cdaf93Tg/yI9IwXfFHon0PTATTsyMan9D7E0vr3IQ675ahLRE8ZUn8Q==";
          };

          nativeBuildInputs = with pkgs; [makeWrapper];

          installPhase = ''
            mkdir -p $out/bin $out/libexec/junit
            cp ${jar} $out/libexec/junit/junit-platform-console-standalone.jar
            makeWrapper ${pkgs.jdk17_headless}/bin/java $out/bin/junit \
              --add-flags "-jar" \
              --add-flags "$out/libexec/junit/junit-platform-console-standalone.jar"
          '';

          dontUnpack = true;
          dontPatch = true;
          dontConfigure = true;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [python3 python3Packages.icecream];
        };
      }
    );
}
