# flake.nix
{
  description = "Acadia CLI packaged for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        acadia = pkgs.stdenv.mkDerivation rec {
          pname = "acadia";
          version = "0.3.0";

          src = pkgs.fetchurl {
            url = "https://get.acadia.engineering/acadia-${version}-linux-x64.gz";
            # nix will tell you the correct hash on first build if you
            # leave this as lib.fakeHash, then swap it in
            sha256 = pkgs.lib.fakeHash;
          };

          # it's a raw .gz, not a tarball, so skip the default unpack
          dontUnpack = true;

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            gzip
          ];

          # add any shared libs the binary links against here
          buildInputs = with pkgs; [
            stdenv.cc.cc.lib
            zlib
          ];

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            gzip -dc $src > $out/bin/acadia
            chmod +x $out/bin/acadia
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Acadia CLI";
            platforms = [ "x86_64-linux" ];
          };
        };
      in
      {
        packages.default = acadia;
        packages.acadia = acadia;

        apps.default = {
          type = "app";
          program = "${acadia}/bin/acadia";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ acadia ];
        };
      });
}
