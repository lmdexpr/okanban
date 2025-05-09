{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) stdenv lib;
in {
  nodeDependencies = stdenv.mkDerivation {
    name = "okanban-client-node-dependencies";
    
    buildInputs = with pkgs; [
      nodejs
      nodePackages.npm
    ];
    
    src = ./.;
    
    buildPhase = ''
      export HOME=$PWD
      npm install
    '';
    
    installPhase = ''
      mkdir -p $out
      cp -r node_modules $out/
      cp package.json $out/
      cp package-lock.json $out/
    '';
    
    dontFixup = true;
  };
}
