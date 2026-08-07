{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.08.1";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/flake.nix.tpl by enumctl/hack/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "7adc8aaeb4b4eb99eacb9c915744fbfd96995173483343e43ff638a7f25e34b3";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "76e9c51184ed2c61ae3468aa3f834bdf7b94321bc0d7f1ad5d766f05985d09b4";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "ddb10c818fab9a4886b907bdc092e7af0f2aabbd22fe4c2b03f073c485d2221b";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "7e0079a27e2562fda77c5bdba491adde8db2b8c13f53018ac1dce1a6db6042ed";
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
