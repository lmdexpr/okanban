{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    opam-repository = { url = "github:ocaml/opam-repository"; flake = false; };

    flake-utils.url = "github:numtide/flake-utils";

    opam-nix = {
      url = "github:tweag/opam-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        opam-repository.follows = "opam-repository";
      };
    };
  };

  outputs = { self, flake-utils, opam-nix, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        
        src = ./.;
        localName = "okanban";

        localPackagesQuery = {
          ${localName} = "*";
        };

        devPackagesQuery = {
          ocaml-base-compiler = "*";
          ocaml-lsp-server = "*";
        };

        query = devPackagesQuery // localPackagesQuery;

        overlay = self: super:
          with builtins;
          let
            super' = mapAttrs
              (p: _:
                if hasAttr "passthru" super.${p} && hasAttr "pkgdef" super.${p}.passthru
                then super.${p}.overrideAttrs (_: { opam__with_test = "false"; opam__with_doc = "false"; })
                else super.${p})
              super;
            local' = mapAttrs
              (p: _:
                super.${p}.overrideAttrs (_: {
                  doNixSupport = false;
                }))
              localPackagesQuery;
          in
          super' // local';

        scope =
          let
            scp = on.buildOpamProject'
              {
                inherit pkgs;
                resolveArgs = { with-test = true; with-doc = true; };
                pinDepends = true;
              }
              src
              query;
          in
          scp.overrideScope overlay;

        devPackages = builtins.attrValues
          (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope);

        okanban-client = pkgs.buildNpmPackage {
          pname = "okanban-client";
          version = "0.1.0";
          src = ./client;

          npmDepsHash = "sha256-oVFQDov55ROy5A9POBdBat3HkGSnhWNCb9/O8N7nmE8=";

          buildPhase = ''
            runHook preBuild
            npm run build
            npm run webpack
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/public
            cp ../public/bundle.js $out/public/bundle.js
            cp -r ../public/index.html $out/ || true
            cp -r ../public/styles.css $out/ || true
            runHook postInstall
          '';
        };
      in {
        legacyPackages = pkgs;

        packages = {
          default = self.packages.${system}.okanban;
          
          okanban = scope.${localName};

          okanban-client = okanban-client;
        };
        
        devShells.default =
          pkgs.mkShell {
            inputsFrom = builtins.map (p: scope.${p}) [ localName ];
            buildInputs = devPackages ++ [
              pkgs.nodePackages.npm
              pkgs.nil pkgs.nixpkgs-fmt
              pkgs.rescript-language-server
            ];
          };
      }
    );
}
