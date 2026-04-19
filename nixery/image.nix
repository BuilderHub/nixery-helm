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
      ./patches/prometheus-metrics.patch
    ];
  };
in
(import "${patched}/default.nix" { inherit pkgs; }).nixery-image
