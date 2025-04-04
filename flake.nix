{
  description = "A module collection for Hjem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
    extendedLib = nixpkgs.lib.extend (final: prev: import ./modules/lib/default.nix {lib = prev;});
  in {
    nixosModules = {
      hjem-rum = import ./modules/nixos.nix {lib = extendedLib;};
      default = self.nixosModules.hjem-rum;
    };

    lib = extendedLib;

    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            pre-commit
            python312Packages.mdformat
            python312Packages.mdformat-footnote
            python312Packages.mdformat-toc
            python312Packages.mdformat-gfm
          ];
          shellHook = ''
            pre-commit install
          '';
        };
      }
    );

    # Provide the default formatter to invoke on 'nix fmt'.
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
