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
    hjemModules = {
      hjem-rum = import ./modules/hjem.nix {lib = extendedLib;};
      default = self.hjemModules.hjem-rum;
    };

    lib = extendedLib;

    # Provide the default formatter to invoke on 'nix fmt'.
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
