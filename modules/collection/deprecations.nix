{rumLib, ...}: let
  inherit (rumLib.modules.deprecations) mkRenamedOptionModuleUntil;
in {
  imports = [
    # deprecations
    (mkRenamedOptionModuleUntil
      ["rum" "programs" "zsh" "integrations" "starship" "enable"]
      ["rum" "programs" "starship" "integrations" "zsh" "enable"]
      "2025-09-20")
    (mkRenamedOptionModuleUntil
      ["rum" "programs" "hyprland"]
      ["rum" "desktops" "hyprland"]
      "2025-09-20")

    (mkRenamedOptionModuleUntil
      ["rum" "gtk"]
      ["rum" "misc" "gtk"]
      "2025-09-20")
  ];
}
