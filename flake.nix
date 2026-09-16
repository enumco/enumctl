{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.09.10";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/nix/flake.nix.tpl by enumctl/hack/nix/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "a5ead7809018509a5d09a2a955400ce4bf8982af889bf17481cd7dbc2b35b357";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "211f1ca4674854a1657532f0bebab03b6f7ebbcc82e09e1a3a5763485766c945";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "59354ff5124ec19a1af0a4badc53b172fb20428995a42324a28c7ccd2316812b";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "73a7372b60f508db8d44bf852658209771ff6f25145195c8600f0d35dacdb01a";
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
