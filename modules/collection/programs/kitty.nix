{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.generators) mkKeyValueDefault;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) nullOr path attrsOf str;
  inherit (lib.attrsets) optionalAttrs mapAttrs' nameValuePair;

  keyValueSettings = {
    listsAsDuplicateKeys = true;
    mkKeyValue = mkKeyValueDefault {} " ";
  };

  keyValue = pkgs.formats.keyValue keyValueSettings;

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
        [kitty.conf's online reference]: https://sw.kovidgoyal.net/kitty/conf/

        The configuration converted and written to {file}`$HOME/.config/kitty/kitty.conf`.
        Please reference [kitty.conf's online reference] or the {manpage}`kitty.conf(5)` for config options.
      '';
    };

    theme = {
      no-preference = mkOption {
        type = nullOr path;
        default = null;
        example = "${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Vivendi.conf";
        description = ''
          [kitty-themes' repository]: https://github.com/kovidgoyal/kitty-themes

          Single theme to be linked to {file}`$HOME/.config/kitty/no-preference-theme.auto.conf`.
          Please reference [kitty-themes' repository] for available themes.
        '';
      };
      light = mkOption {
        type = nullOr path;
        default = null;
        example = "${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Operandi.conf";
        description = ''
          [kitty-themes' repository]: https://github.com/kovidgoyal/kitty-themes

          Light theme to be linked to {file}`$HOME/.config/kitty/light-theme.auto.conf`.
          Please reference [kitty-themes' repository] for available themes.
        '';
      };
      dark = mkOption {
        type = nullOr path;
        default = null;
        example = "${pkgs.kitty-themes}/share/kitty-themes/themes/Modus_Vivendi.conf";
        description = ''
          [kitty-themes' repository]: https://github.com/kovidgoyal/kitty-themes

          Dark theme to be linked to {file}`$HOME/.config/kitty/dark-theme.auto.conf`.
          Please reference [kitty-themes' repository] for available themes.
        '';
      };
    };

    extraConfFiles = mkOption {
      type = attrsOf str;
      default = {};
      example = {
        "diff.conf" = ''
          num_context_lines 3
          ignore_name .git
        '';
      };
      description = ''
        [kitty kittens' online reference]: https://sw.kovidgoyal.net/kitty/kittens_intro/

        Extra configuration files written to {file}`$HOME/.config/kitty/`.
        Please reference [kitty kittens' online reference] for options.
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

        ".config/kitty/no-preference-theme.auto.conf".source = mkIf (cfg.theme.no-preference != "") cfg.theme.no-preference;
        ".config/kitty/light-theme.auto.conf".source = mkIf (cfg.theme.light != "") cfg.theme.light;
        ".config/kitty/dark-theme.auto.conf".source = mkIf (cfg.theme.dark != "") cfg.theme.dark;
      }
      // optionalAttrs (cfg.extraConfFiles != {}) (mapAttrs'
        (
          name: val:
            nameValuePair ".config/kitty/${name}" {text = val;}
        )
        cfg.extraConfFiles);
  };
}
