/*
Helper function to import the testing framework with special args.

This function imports runTest from nixpkgs:/nixos/lib/testing-lib/runTest
to run our test derivation (the argument of this function),
passing some args in the process, notably self, allowing us to
use inputs and outputs from our flake.

Usage: (import ./location-of-lib.nix) {test-script-here}
*/
{
  pkgs,
  self,
  lib,
  testDirectory,
}: let
  inherit (builtins) filter;
  inherit (lib.trivial) pipe;
  inherit (lib.strings) hasSuffix;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.attrsets) listToAttrs;

  nixos-lib = import (pkgs.path + "/nixos/lib") {};

  runTest = test:
    nixos-lib.runTest {
      hostPkgs = pkgs;
      defaults = {
        documentation.enable = lib.mkDefault false;
        imports = [self.inputs.hjem.nixosModules.default];
        hjem.extraModules = [self.hjemModules.bare]; # We import the bare module to check for module dependencies
        users.groups.bob = {};
        users.users.bob = {
          isNormalUser = true;
          password = "";
        };
      };
      node.specialArgs = {inherit self lib;};
      imports = [test];
    };

  tests = pipe testDirectory [
    listFilesRecursive
    (filter (hasSuffix ".nix"))
    (map runTest)
    (map (test: {
      inherit (test) name;
      value = test;
    }))
    listToAttrs
  ];
in
  tests
