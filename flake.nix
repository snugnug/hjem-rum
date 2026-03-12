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
      inputs.ndg.follows = "ndg";
    };

    # Avoid overriding the Nixpkgs of NDG, or otherwise it will have to be rebuilt.
    # Alternative here is using the binary releases, but it is bound to get into
    # Nixpkgs eventually, so for now the duplicate Nixpkgs is *acceptable*.
    # FIXME: remove when NDG is in Nixpkgs
    ndg.url = "github:feel-co/ndg?ref=v2.5.1"; # pin NDG to benefit from binary cache
  };

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    ndg,
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
        inherit rumLib inputs;
      };
      default = self.hjemModules.hjem-rum;
    };
    packages = forAllSystems (pkgs: {
      docs = pkgs.callPackage ./docs/package.nix {
        inherit (ndg.packages.${pkgs.system}) ndg;
        inherit rumLib inputs;
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
          testDirectory = ./modules/tests/collection;
        }
    );

    # Provide the default formatter to invoke on 'nix fmt'.
    formatter = forAllSystems (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
  };
}
