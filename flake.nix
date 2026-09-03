{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.09.4";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/flake.nix.tpl by enumctl/hack/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "d34a30c9fe295879da0d21dbf8b3fa5874efa4111e4cc6b324d00699830fe265";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "47bd0bf5059fae92f1bbef835dc485d1cee0ccce95c4e743eea187d69fc2ba4b";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "10d7408d28bcd71086215e7a407ed67a0bce3c83ef549cf632cbe141545a04f7";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "fb70b03d9c6c2703e89bb8eb8eddb0489e44865bad12da1c7645c8c21e8881ca";
        };
      };

      systems = builtins.attrNames artifacts;
      forAllSystems = nixpkgs.lib.genAttrs systems;

      enumctlFor =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          artifact = artifacts.${system};
        in
        pkgs.stdenv.mkDerivation {
          pname = "enumctl";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://dl.enum.co/enumctl/${version}/${artifact.file}";
            inherit (artifact) sha256;
          };

          dontUnpack = true;

          # Current Linux builds are statically linked, so autoPatchelfHook is a
          # no-op. Kept as a safety net: if a future build links against glibc, it
          # patches the ELF interpreter/rpath to the nixpkgs runtime. macOS: none.
          nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.autoPatchelfHook
          ];

          installPhase = ''
            runHook preInstall
            install -Dm755 $src $out/bin/enumctl
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "CLI for managing enum cloud infrastructure";
            homepage = "https://enum.co/";
            platforms = systems;
            sourceProvenance = [ sourceTypes.binaryNativeCode ];
            mainProgram = "enumctl";
          };
        };
    in
    {
      packages = forAllSystems (system: rec {
        enumctl = enumctlFor system;
        default = enumctl;
      });
    };
}
