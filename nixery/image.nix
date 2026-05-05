# Build nixery-image from upstream sources in ../nixery-src with patches applied.
# CI checks out tazjin/nixery into nixery-src; local builds need the same layout.
let
  pkgs = import <nixpkgs> { };
  patched = pkgs.applyPatches {
    name = "nixery-patched";
    src = ../nixery-src;
    patches = [
      ./patches/s3-use-path-style-env.patch
      ./patches/s3-putobject-spool-seekable.patch
      ./patches/channel-url-source.patch
    ];
    postPatch = ''
      substituteInPlace default.nix \
        --replace 'export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt' 'export SSL_CERT_FILE=''${cacert}/etc/ssl/certs/ca-bundle.crt
export NIX_SSL_CERT_FILE=''${cacert}/etc/ssl/certs/ca-bundle.crt
export GIT_SSL_CAINFO=''${cacert}/etc/ssl/certs/ca-bundle.crt'

      substituteInPlace prepare-image/prepare-image.nix \
        --replace ' deepFetch = with lib; s: n:' ' # Dynamic flake package components are encoded into a single Docker path
 # component so they do not collide with the Nixery "/" package separator.
 #
 # Example:
 #   flake--github--coreweave--buildweave--default--main
 # becomes:
 #   builtins.getFlake "github:coreweave/buildweave/main"
 #   .packages.''${system}.default
 dynamicFlakeFetch = with lib; n:
 let
 parts = splitString "--" n;
 err = { error = "not_found"; pkg = n; };
 valid =
 (length parts) == 6
 && (builtins.elemAt parts 0) == "flake"
 && (builtins.elemAt parts 1) == "github"
 && (builtins.elemAt parts 2) != ""
 && (builtins.elemAt parts 3) != ""
 && (builtins.elemAt parts 4) != ""
 && (builtins.elemAt parts 5) != "";
 owner = builtins.elemAt parts 2;
 repo = builtins.elemAt parts 3;
 package = builtins.elemAt parts 4;
 ref = builtins.elemAt parts 5;
 flake = builtins.getFlake "github:''${owner}/''${repo}/''${ref}";
 packages = attrByPath [ "packages" system ] null flake;
 in
 if !valid || packages == null then err else attrByPath (splitString "." package) err packages;

 deepFetch = with lib; s: n:
 if hasPrefix "flake--" n then dynamicFlakeFetch n else'
    '';
  };
in
(import "${patched}/default.nix" { inherit pkgs; }).nixery-image
