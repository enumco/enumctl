# enumctl

[`enumctl`](https://enum.co/) is the command-line interface for managing enum
cloud infrastructure. This repository packages the precompiled `enumctl`
binaries as a Nix flake.

> **Auto-generated.** This repository is published by CI on every `enumctl`
> release. Do not edit `flake.nix`, `flake.lock`, or this README by hand -
> changes are overwritten on the next release.

Pinned version: **2026.07.3**

## Requirements

Nix with flakes enabled. Add to `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

or pass `--extra-experimental-features 'nix-command flakes'` per command.

## Usage

Run without installing:

```bash
nix run github:enumco/enumctl -- --help
```

Install into a profile:

```bash
nix profile install github:enumco/enumctl
```

Add as a flake input:

```nix
{
  inputs.enumctl.url = "github:enumco/enumctl";
}
```

The flake exposes `packages.<system>.enumctl` (the default package) for
`x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin`.

## Pinning a version

`github:enumco/enumctl` always tracks the latest published release. To pin a
specific build, reference a commit:

```bash
nix run github:enumco/enumctl/<commit-sha> -- --help
```

## How it works

The binaries are downloaded from `https://dl.enum.co/enumctl/<version>/` and
verified against the SHA-256 checksums pinned in `flake.nix`.
