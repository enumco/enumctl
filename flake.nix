{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.08.3";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/flake.nix.tpl by enumctl/hack/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "7caa767885cf506be219dfaa5cfbc0434ca722008a34c4f884da4dc9474d73a3";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "9c051f7615319c5520fd9bb5d8621995e2952014019a2c0c7b46695809b0572c";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "42339c84a40b5b6ade04abd8139f658ef6b7e558631a39cf34654099b0fdaa33";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "061e5f833293a72dc5b9aae677d87eb569d3d6e5b92cf795a5edca02a4611cdc";
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
