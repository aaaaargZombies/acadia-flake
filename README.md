# acadia-flake

A Nix flake that packages the [Acadia](https://get.acadia.engineering) CLI binary for use in other Nix projects.

Acadia isn't published to nixpkgs, so this flake fetches the prebuilt binary
release directly, patches it to run under Nix (on Linux), and exposes it as
a `packages` output that other flakes can depend on.

## Usage

### Run it directly

```sh
nix run github:youruser/acadia-flake
```

### Try it in a shell

```sh
nix develop github:youruser/acadia-flake
acadia --help
```

### Use it as a dependency in another flake

Add it to your `inputs`:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  acadia.url = "github:youruser/acadia-flake";
};
```

Then reference `acadia.packages.${system}.default` wherever you build a
devShell or package list:

```nix
outputs = { self, nixpkgs, acadia }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        acadia.packages.${system}.default
      ];
    };
  };
```

## Status

All four supported systems have verified source hashes in `flake.nix`.

Windows is not supported by this flake — Nix doesn't build for a
`x86_64-windows` platform in the conventional sense. If you need Acadia on
Windows, use the vendor's own install instructions instead.

## Supported systems

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Outputs

This flake currently exposes:

- `packages.<system>.default` / `packages.<system>.acadia` — the packaged
  binary. This is the output other flakes should reference as a dependency.
- `apps.<system>.default` — lets you run it directly with `nix run`,
  without adding it as a dependency elsewhere.
- `devShells.<system>.default` — drops you into a shell with `acadia` on
  `PATH`, useful for testing this flake in isolation.

`apps` and `devShells` are kept in for now for convenience while iterating
on this flake (quick sanity checks with `nix run` / `nix develop`), even
though projects that consume this as an input generally only need
`packages`.

## Updating the Acadia version

Bump the `version` string in `flake.nix`, then re-fetch all four hashes
(the old ones won't be valid for a new release):

```sh
nix-prefetch-url https://get.acadia.engineering/acadia-<version>-<suffix>.gz
```

for each of `linux-x64`, `linux-arm`, `mac-x64`, `mac-arm`, and update the
corresponding `hash` field in the `targets` attrset in `flake.nix`.

Note that `x86_64-darwin` and `aarch64-darwin` builds should be done
natively on a Mac of the matching architecture — cross-building isn't set
up here.
