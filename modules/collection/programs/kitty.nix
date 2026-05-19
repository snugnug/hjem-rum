{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.generators) mkKeyValueDefault;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) nullOr path;

  kittyKeyValue = pkgs.formats.keyValue {
    listsAsDuplicateKeys = true;
    mkKeyValue = mkKeyValueDefault {} " ";
  };

  cfg = config.rum.programs.kitty;
in {
  options.rum.programs.kitty = {
    enable = mkEnableOption "kitty";

    package = mkPackageOption pkgs "kitty" {nullable = true;};

    settings = mkOption {
      type = kittyKeyValue.type;
      default = {};
      example = {
        font_family = "RobotoMono";
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/kitty/kitty.conf`.
        Please reference [kitty's documentation] for config options.

        [kitty's documentation]: https://sw.kovidgoyal.net/kitty/conf/
      '';
    };

    theme = {
      light = mkOption {
        type = nullOr path;
        default = null;
        example = "${pkgs.kitty-themes}/share/kitty-themes/themes/1984_light.conf";
        description = ''
          Light theme to be linked to {file}`$XDG_CONFIG_HOME/kitty/light-theme.auto.conf`.
          This theme is set when your OS theme is set to light.

          Please reference [kitty-themes' repository] for available themes.

          [kitty-themes' repository]: https://github.com/kovidgoyal/kitty-themes
        '';
      };
      dark = mkOption {
        type = nullOr path;
        default = null;
        example = "${pkgs.kitty-themes}/share/kitty-themes/themes/1984_dark.conf";
        description = ''
          Dark theme to be linked to {file}`$XDG_CONFIG_HOME/kitty/dark-theme.auto.conf`.
          This theme is set when your OS theme is set to dark.

          Please reference [kitty-themes' repository] for available themes.

          [kitty-themes' repository]: https://github.com/kovidgoyal/kitty-themes
        '';
      };
      no-preference = mkOption {
        type = nullOr path;
        default = null;
        example = "${pkgs.kitty-themes}/share/kitty-themes/themes/default.conf";
        description = ''
          no-preference theme to be linked to {file}`$XDG_CONFIG_HOME/kitty/no-preference-theme.auto.conf`.
          This theme is set when your OS does not specify any theme preference.

          Please reference [kitty-themes' repository] for available themes.

          [kitty-themes' repository]: https://github.com/kovidgoyal/kitty-themes
        '';
      };
    };

    integrations = {
      fish.enable =
        mkEnableOption "kitty integration with fish"
        // {
          default = true;
          example = false;
        };
      zsh.enable =
        mkEnableOption "kitty integration with zsh"
        // {
          default = true;
          example = false;
        };
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files = {
      "kitty/kitty.conf" = mkIf (cfg.settings != {}) {
        source = kittyKeyValue.generate "kitty.conf" (
          cfg.settings
          // optionalAttrs ((cfg.integrations.fish.enable && config.rum.programs.fish.enable) || (cfg.integrations.zsh.enable && config.rum.programs.zsh.enable)) {shell_integration = "no-rc";}
        );
      };
      "kitty/light-theme.auto.conf" = mkIf (cfg.theme.light != null) {source = cfg.theme.light;};
      "kitty/dark-theme.auto.conf" = mkIf (cfg.theme.dark != null) {source = cfg.theme.dark;};
      "kitty/no-preference-theme.auto.conf" = mkIf (cfg.theme.no-preference != null) {source = cfg.theme.no-preference;};
    };

    rum.programs.fish.config = mkIf cfg.integrations.fish.enable (
      mkAfter ''
        source "${cfg.package.shell_integration}/fish/vendor_conf.d/kitty-shell-integration.fish"
        set --prepend fish_complete_path "${cfg.package.shell_integration}/fish/vendor_completions.d"
      ''
    );
    rum.programs.zsh.initConfig = mkIf cfg.integrations.zsh.enable (
      mkAfter ''
        autoload -Uz -- ${cfg.package.shell_integration}/zsh/kitty-integration
        kitty-integration
        unfunction kitty-integration
      ''
    );
  };
}
