{
  description = "enumctl - CLI for managing enum cloud infrastructure (precompiled binary)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2026.06.3";

      # Upstream artifact filename and hex sha256 per Nix system.
      # Generated from enumctl/hack/flake.nix.tpl by enumctl/hack/update-nix.sh.
      # Checksums match the binaries published at
      # https://dl.enum.co/enumctl/${version}/ for the pinned version.
      artifacts = {
        "x86_64-linux" = {
          file = "enumctl-linux-amd64";
          sha256 = "cce63e87d6f42c5bb86f6db5d67c5f1eef38cc0b9b2567bbf236fd495268db06";
        };
        "aarch64-linux" = {
          file = "enumctl-linux-arm64";
          sha256 = "dd10af443448f6e012efbf999510f21a158720d52c8f06ac02e4d452201d5fd9";
        };
        "x86_64-darwin" = {
          file = "enumctl-darwin-amd64";
          sha256 = "b8891880d79d190d40995444c4166af5fd2c56fd35f242ff6672f3ea561ed1c7";
        };
        "aarch64-darwin" = {
          file = "enumctl-darwin-arm64";
          sha256 = "f22f45e2f8dea5efee415b4897d65f83eb16c2cce8170fd7c830147fe7eeb8f8";
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
