{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) mapAttrs' nameValuePair optionalAttrs;
  inherit (lib.generators) mkKeyValueDefault;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) attrsOf;

  keyValueSettings = {
    listsAsDuplicateKeys = true;
    mkKeyValue = mkKeyValueDefault {} " = ";
  };

  keyValue = pkgs.formats.keyValue keyValueSettings;

  mkThemes = themes:
    mapAttrs'
    (name: value:
      nameValuePair
      ".config/ghostty/themes/${name}"
      {
        source = keyValue.generate "ghostty-${name}-theme" value;
      })
    themes;

  cfg = config.rum.programs.ghostty;
in {
  options.rum.programs.ghostty = {
    enable = mkEnableOption "Ghostty";

    package = mkPackageOption pkgs "ghostty" {};

    settings = mkOption {
      type = keyValue.type;
      default = {};
      example = {
        theme = "example-theme";
        font-size = 10;
        keybind = [
          "ctrl+h=goto_split:left"
          "ctrl+l=goto_split:right"
        ];
      };
      description = ''
        The configuration converted to INI and written to `${config.directory}/.config/ghostty/config`.
        Please reference https://ghostty.org/docs/config/reference for config options.
      '';
    };
    themes = mkOption {
      type = attrsOf keyValue.type;
      default = {};
      example = {
        example-theme = {
          palette = [
            "0=#51576d"
            "1=#e78284"
            "2=#a6d189"
            "3=#e5c890"
            "4=#8caaee"
            "5=#f4b8e4"
            "6=#81c8be"
            "7=#a5adce"
            "8=#626880"
            "9=#e67172"
            "10=#8ec772"
            "11=#d9ba73"
            "12=#7b9ef0"
            "13=#f2a4db"
            "14=#5abfb5"
            "15=#b5bfe2"
          ];
          background = "#303446";
          foreground = "#c6d0f5";
          cursor-color = "#f2d5cf";
          cursor-text = "#c6d0f5";
          selection-background = "#626880";
          selection-foreground = "#c6d0f5";
        };
      };
      description = ''
        An attribute set of themes, with the key as the theme name.
        Please reference https://ghostty.org/docs/features/theme for config options.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files =
      {
        ".config/ghostty/config".source = mkIf (cfg.settings != {}) (
          keyValue.generate "ghostty-config" cfg.settings
        );
      }
      // optionalAttrs (cfg.themes != {}) (mkThemes cfg.themes);
  };
}
