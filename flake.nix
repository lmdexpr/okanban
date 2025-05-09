{
  description = "OKanban - Simple Kanban app written in OCaml";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ocamlPackages = pkgs.ocaml-ng.ocamlPackages_5_3;
        
        # Frontend dependencies
        nodeDependencies = (pkgs.callPackage ./client/default.nix {}).nodeDependencies;
      in {
        packages = {
          default = self.packages.${system}.okanban;
          
          okanban = pkgs.stdenv.mkDerivation {
            name = "okanban";
            src = ./.;
            
            nativeBuildInputs = with pkgs; [
              ocamlPackages.dune_3
              ocamlPackages.findlib
              ocamlPackages.ocaml
              nodejs
              nodePackages.npm
            ];
            
            buildInputs = with ocamlPackages; [
              dream
              yojson
              ppx_deriving_yojson
              ppx_fields_conv
              odoc
            ];
            
            buildPhase = ''
              # Build OCaml backend
              dune build
              
              # Build frontend
              mkdir -p client/node_modules
              cp -r ${nodeDependencies}/* client/node_modules/
              chmod -R +w client/node_modules
              
              cd client
              npm run build
              npm run webpack
              cd ..
            '';
            
            installPhase = ''
              mkdir -p $out/bin
              mkdir -p $out/public
              
              cp -r _build/default/bin/main.exe $out/bin/okanban
              cp -r public/* $out/public/
            '';
          };
        };
        
        apps.default = {
          type = "app";
          program = "${self.packages.${system}.okanban}/bin/okanban";
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # OCaml
            ocamlPackages.ocaml
            ocamlPackages.dune_3
            ocamlPackages.findlib
            ocamlPackages.dream
            ocamlPackages.yojson
            ocamlPackages.ppx_deriving_yojson
            ocamlPackages.ppx_fields_conv
            ocamlPackages.odoc
            ocamlPackages.ocaml-lsp
            ocamlPackages.ocamlformat
            
            # Node.js
            nodejs
            nodePackages.npm
            nodePackages.typescript
            nodePackages.webpack
            nodePackages.webpack-cli
          ];
        };
      }
    );
}
