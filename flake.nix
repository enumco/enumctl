{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.06.4";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/flake.nix.tpl by enumctl/hack/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "e6c55e9fad5841a5ae553061bb83ae9ccbea9fc8b53339759338e1160a3780b1";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "37f6b7929bd10a10694a9c4060c0a0ee569f43d0d799bbf7c111d428b614f71c";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "30457c70327fe399cff503ade5471b041df9b4e135c84ff330cd1f9b175e24e7";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "a4d1c4228962650ebeb20ab7dd99d660cc03d1b8ad6ff419632a9023795c5d9b";
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
