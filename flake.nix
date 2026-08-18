{
  description = "Acadia CLI packaged for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f system);

      version = "0.3.0";

      targets = {
        x86_64-linux = {
          suffix = "linux-x64";
          hash = "sha256-3KT/RnyxZhe3xfoI+R++T9GxY4DOTJuicRyVcudBMsI=";
        };
        aarch64-linux = {
          suffix = "linux-arm";
          hash = "0sl8ywv6b0k5myx0vv9mlwrrr5qrfyyiid2psb8x8s2xyycj8a06";
        };
        x86_64-darwin = {
          suffix = "mac-x64";
          hash = "111mz47mbkgb6wp9mmvjpy59j66xll91dlrnnd3wkih907g17vlk";
        };
        aarch64-darwin = {
          suffix = "mac-arm";
          hash = "0vwz4xflia6mjbxadvkn9pixd7islqff6irw78npsb6dz41hwnd3";
        };
      };

      mkAcadia = system:
        let
          pkgs = import nixpkgs { inherit system; };
          target = targets.${system};
          isLinux = pkgs.stdenv.hostPlatform.isLinux;
        in
        pkgs.stdenv.mkDerivation {
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

          postFixup = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
            codesign --remove-signature $out/bin/acadia || true
            codesign -s - $out/bin/acadia || true
          '';

          meta = with pkgs.lib; {
            description = "Acadia CLI";
            platforms = systems;
          };
        };
    in
    {
      packages = forAllSystems (system: {
        default = mkAcadia system;
        acadia = mkAcadia system;
      });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${mkAcadia system}/bin/acadia";
        };
      });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            buildInputs = [ (mkAcadia system) ];
          };
        });
    };
}
