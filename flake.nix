{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.10.2";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/nix/flake.nix.tpl by enumctl/hack/nix/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "38daf10a4f1c60f805691e36d833a9a1a7f016d4210b896b6b7e77f61cff45a5";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "7d34510475ea56e13b18b0487f01595da99d732fce9dae4aa218ca4e4dd51e26";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "5ac336c651efca91c2ae82fb89bdaf7dca4600500a29e4a05cb900e038a8111e";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "f6df411a8f06540f9239ad663ca6e1dd72da247904a6a3a8ff3580ca4ada217a";
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
