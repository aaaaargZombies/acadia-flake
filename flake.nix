# flake.nix
{
  description = "Acadia CLI packaged for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = "0.3.0";

        # per-system download suffix + hash
        # run `nix build .#acadia --system <system>` once with fakeHash,
        # copy the "got:" hash it reports into the table below
        targets = {
          x86_64-linux = {
            suffix = "linux-x64";
            hash = pkgs.lib.fakeHash;
          };
          aarch64-linux = {
            suffix = "linux-arm";
            hash = pkgs.lib.fakeHash;
          };
          x86_64-darwin = {
            suffix = "mac-x64";
            hash = pkgs.lib.fakeHash;
          };
          aarch64-darwin = {
            suffix = "mac-arm";
            hash = pkgs.lib.fakeHash;
          };
        };

        target = targets.${system};
        isLinux = pkgs.stdenv.isLinux;

        acadia = pkgs.stdenv.mkDerivation {
          pname = "acadia";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://get.acadia.engineering/acadia-${version}-${target.suffix}.gz";
            sha256 = target.hash;
          };

          dontUnpack = true;

          nativeBuildInputs = with pkgs;
            [ gzip ]
            ++ pkgs.lib.optionals isLinux [ autoPatchelfHook ];

          buildInputs = with pkgs;
            pkgs.lib.optionals isLinux [
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

          # macOS binaries need this instead of autoPatchelf, since they're
          # not code-signed for arbitrary machines
          postFixup = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
            codesign --remove-signature $out/bin/acadia || true
            codesign -s - $out/bin/acadia || true
          '';

          meta = with pkgs.lib; {
            description = "Acadia CLI";
            platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
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
