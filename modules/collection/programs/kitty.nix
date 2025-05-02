{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.generators) mkKeyValueDefault;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) submodule str;

  keyValueSettings = {
    listsAsDuplicateKeys = true;
    mkKeyValue = mkKeyValueDefault {} " ";
  };

  keyValue = pkgs.formats.keyValue keyValueSettings;

  themeType = submodule {
    options = {
      default = mkOption {
        type = str;
        default = "";
      };
      light = mkOption {
        type = str;
        default = "";
      };
      dark = mkOption {
        type = str;
        default = "";
      };
    };
  };

  cfg = config.rum.programs.kitty;
in {
  options.rum.programs.kitty = {
    enable = mkEnableOption "kitty";

    package = mkPackageOption pkgs "kitty" {};

    settings = mkOption {
      type = keyValue.type;
      default = {};
      example = {
        font_size = 10;
        text_composition_strategy = "2.5 0";
        cursor_shape = "beam";
        map = [
          "kitty_mod+l next_layout"
          "ctrl+alt+t goto_layout tall"
        ];
      };
      description = ''
        The configuration converted and written to {file}`$HOME/.config/kitty/kitty.conf`.
        Please reference [kitty.conf's online reference](https://sw.kovidgoyal.net/kitty/conf/) or the {manpage}`kitty.conf(5)` for config options.
      '';
    };

    theme = mkOption {
      type = themeType;
      default = {};
      example.default = "${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Vivendi.conf";
      description = ''
        The theme(s) to be configured.
        For reference themes, use [kitty-themes](https://github.com/kovidgoyal/kitty-themes), which is ${pkgs.kitty-themes} inside nixpkgs.

        If only one theme is desired, this option can be set as a single string:
        ```nix
          theme.default = "${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Vivendi.conf";
        ```
        This will symlink the file to {file}`$HOME/.config/kitty/current-theme.conf`.

        Otherwise, if a light and dark theme is desired, this option needs to be an attribute-set:
        ```nix
          theme = {
            light = "${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Operandi.conf";
            dark = "${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Vivendi.conf";
          };
        ```
        This will symlink the light and dark mode to {file}`$HOME/.config/kitty/light-theme.auto.conf` and {file}`$HOME/.config/kitty/dark-theme.auto.conf`, respectively.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files =
      {
        ".config/kitty/kitty.conf".source = mkIf (cfg.settings != {}) (
          keyValue.generate "kitty.conf" cfg.settings
        );
      }
      // optionalAttrs (cfg.theme != {}) {
        ".config/kitty/current-theme.conf".source = mkIf (cfg.theme.default != "") cfg.theme.default;
        ".config/kitty/light-theme.auto.conf".source = mkIf (cfg.theme.light != "") cfg.theme.light;
        ".config/kitty/dark-theme.auto.conf".source = mkIf (cfg.theme.dark != "") cfg.theme.dark;
      };
  };
}
