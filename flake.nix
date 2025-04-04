{
  description = "A module collection for Hjem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ndg = {
      url = "github:feel-co/ndg/v2";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ndg,
    ...
  } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"];
    extendedLib = nixpkgs.lib.extend (final: prev: import ./modules/lib/default.nix {lib = prev;});
  in {
    nixosModules = {
      hjem-rum = import ./modules/nixos.nix {lib = extendedLib;};
      default = self.nixosModules.hjem-rum;
    };
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      docs = import ./docs {
        inherit inputs pkgs;
        lib = extendedLib;
      };
    });
    lib = extendedLib;

    # Provide the default formatter to invoke on 'nix fmt'.
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
