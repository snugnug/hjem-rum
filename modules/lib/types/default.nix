{lib}: {
  gtkType = import ./gtkType.nix {inherit lib;};
  gvariantType = import ./gvariantType.nix {inherit lib;};
  hyprType = import ./hyprType.nix {inherit lib;};
  ncmpcppBindingType = import ./ncmpcppBindingType.nix {inherit lib;};
  tofiSettingsType = import ./tofiSettingsType.nix {inherit lib;};
}
