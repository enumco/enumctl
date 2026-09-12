{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.09.9";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/nix/flake.nix.tpl by enumctl/hack/nix/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "77596fd4ca723676b17e59cf10de96d4d0ac92f1aeadfbbab02e9d4ca5415735";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "d18882ad2367ca01a22ad147ec2a6b61dc344d29b88f06c12982fff3b3b23f2b";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "b97268073a0cb399ebef43219ce9d3835e16aa548203fbcb0aeb4438825d53f0";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "4d9a2b78848d62f615a2fee50b5076e02b12004c0714a35f0eac23ce4b12c136";
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
          nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
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
            license = licenses.asl20;
            platforms = systems;
            sourceProvenance = [ sourceTypes.binaryNativeCode ];
            mainProgram = "enumctl";
          };
        };

      homeManagerModule =
        { config, lib, pkgs, ... }:
        let
          cfg = config.programs.enumctl;
        in
        {
          options.programs.enumctl = {
            enable = lib.mkEnableOption "enumctl";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.enumctl;
              description = "The enumctl package to install.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
          };
        };
    in
    {
      packages = forAllSystems (system: rec {
        enumctl = enumctlFor system;
        default = enumctl;
      });

      homeManagerModules = {
        default = homeManagerModule;
        enumctl = homeManagerModule;
      };

      homeModules = self.homeManagerModules;
    };
}
