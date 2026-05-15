{
  description = "A module collection for Hjem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    hjem,
    ...
  } @ inputs: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];

    forAllSystems = function:
      nixpkgs.lib.genAttrs
      supportedSystems
      (system: function nixpkgs.legacyPackages.${system});

    rumLib = import ./modules/lib/default.nix {inherit (nixpkgs) lib;};

    treefmtEval = forAllSystems (pkgs:
      (import (import ./npins).treefmt-nix).evalModule pkgs
      {
        projectRootFile = "flake.nix";
        programs.alejandra.enable = true;
        programs.deno.enable = true;
        programs.shfmt.enable = true;

        settings = {
          deno.includes = ["*.md"];
        };
      });
  in {
    hjemModules = {
      hjem-rum = import ./modules/hjem.nix {
        inherit (nixpkgs) lib;
        inherit rumLib inputs;
      };
      default = self.hjemModules.hjem-rum;
    };
    packages = forAllSystems (pkgs: {
      docs = pkgs.callPackage ./docs/package.nix {
        inherit rumLib inputs;
        ndg = (import ((import ./npins).ndg + "/nix") {inherit pkgs;}).packages.default;
      };
    });
    lib = rumLib;

    devShells = forAllSystems (
      pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            npins
            pre-commit
            commitizen
          ];
          inputsFrom = [
            treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.devShell
          ];
          shellHook = ''
            pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
          '';
        };
      }
    );

    # Provides checks to invoke with 'nix flake check'
    checks = forAllSystems (
      pkgs:
        import ./modules/tests {
          inherit self pkgs;
          inherit (nixpkgs) lib;
          testDirectory = ./modules/tests/collection;
        }
    );

    # Provide the default formatter to invoke on 'nix fmt'.
    formatter = forAllSystems (pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);
  };
}
