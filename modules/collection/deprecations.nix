{lib, ...}: let
  inherit (builtins) match trace;
  inherit (lib.asserts) assertMsg;
  inherit (lib.modules) doRename mkRemovedOptionModule;
  inherit (lib.options) showOption;
  isValidISODate = dateString: (match "[0-9]{4}-[0-9]{2}-[0-9]{2}" dateString != null);
  mkRenamedOptionModuleUntil = from: to: date:
    assert assertMsg (isValidISODate date) "Cannot rename `${showOption from}` to `${showOption to}`: Your date needs to be in ISO 8601 format, ie. yyyy-mm-dd (got ${date} instead).";
      doRename {
        inherit from to;
        visible = false;
        warn = true;
        use = trace "Obsolete option `${showOption from}' is used. It was renamed to `${showOption to}', and will be removed on ${date}";
      };
in {
  imports = [
    (mkRemovedOptionModule
      ["rum" "programs" "git" "destination"]
      "The default destination is now under `~/.config/git`")

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
