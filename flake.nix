{
  description = "A module collection for Hjem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ndg = {
      url = "github:feel-co/ndg";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    ndg,
    ...
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];

    forAllSystems = function:
      nixpkgs.lib.genAttrs
      supportedSystems
      (system: function nixpkgs.legacyPackages.${system});

    rumLib = import ./modules/lib/default.nix {inherit (nixpkgs) lib;};
    treefmtEval = forAllSystems (pkgs:
      treefmt-nix.lib.evalModule pkgs
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
        inherit rumLib;
      };
      default = self.hjemModules.hjem-rum;
    };
    packages = forAllSystems (pkgs: {
      docs = pkgs.callPackage ./docs/package.nix {
        inherit (ndg.packages.${pkgs.system}) ndg;
        inherit rumLib;
      };
    });
    lib = rumLib;

    devShells = forAllSystems (
      pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            pre-commit
            python312Packages.commitizen
          ];
          inputsFrom = [
            treefmtEval.${pkgs.system}.config.build.devShell
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
          testDirectory = ./modules/tests/programs;
        }
    );

    # Provide the default formatter to invoke on 'nix fmt'.
    formatter = forAllSystems (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
  };
}
