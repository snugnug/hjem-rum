# copied from https://github.com/hyprwm/Hyprland/blob/ff97d18c4c61ae14f8f3b80178e6b72c8a4b7901/nix/module.nix#L23-L38
{lib}: let
  inherit (lib.types) attrsOf listOf nullOr oneOf bool float int path str;
  valueType =
    nullOr (oneOf [
      bool
      int
      float
      str
      path
      (attrsOf valueType)
      (listOf valueType)
    ])
    // {
      description = "Hyprland configuration value";
    };
in
  valueType
