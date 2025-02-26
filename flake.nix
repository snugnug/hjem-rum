{
  description = "A module collection for Hjem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
    extendedLib = nixpkgs.lib.extend (_: prev: import ./modules/lib/default.nix {lib = prev;});
  in {
    # Provide the default formatter to invoke on 'nix fmt'.
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Nixos modules exposed by this flake
    nixosModules = {
      hjem-rum = import ./modules/nixos.nix {lib = extendedLib;};
      default = self.nixosModules.hjem-rum;
    };

    # Provides checks to invoke with 'nix flake check'
    checks = forAllSystems (system: let
      mkCheckArgs = testDirectory: {
        inherit self;
        inherit testDirectory;
	lib = extendedLib;
        pkgs = nixpkgs.legacyPackages.${system};
      };
    in {
      pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          alejandra.enable = true;
          deadnix.enable = true;
        };
      };
      hjem-rum-modules = import ./modules/tests (mkCheckArgs ./modules/tests/programs);
    });

    # Provides devshells to invoke with 'nix develop'
    devShells = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
      };
    });
  };
}
