{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.09.11";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/nix/flake.nix.tpl by enumctl/hack/nix/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "840a677481c3e1e49be8ee8eaebf70032fb5c842f06fb6061ee89c049cb7e3eb";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "058f16ddc77873ed663aea40b2da5b680505d78998b503619a11866ce212e89c";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "6e97f237e6bcff3f8706a2785c0ca0f8ad93d771852cb038611f8b00c9534084";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "873175b413886cdefede16da6095ef04a9ff45c0b8869dec2054865271a20084";
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
