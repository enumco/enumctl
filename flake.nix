{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.09.6";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/nix/flake.nix.tpl by enumctl/hack/nix/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "e9f98b870584226aefc60322b0f518ea0df728cc3793882771506cba799ff771";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "fd9daf8aa5aed7060cd52e45e1044fdc05aa498e3b4ad4e89066c67849eb9085";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "9e50c996ca8932fa5292c6083c1d2fce6f4919c1db985938beccfefbb5ba6c9d";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "e123a71fb09a18851f52705bd6356144ef7dae204b7ea750787d4c935f8de6d1";
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
