# Build nixery-image from upstream sources in ../nixery-src.
# CI checks out tazjin/nixery into nixery-src; local builds need the same layout.
let
  pkgs = import <nixpkgs> { };
in
(import ../nixery-src/default.nix { inherit pkgs; }).nixery-image
