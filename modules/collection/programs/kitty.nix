{
  lib,
  pkgs,
  config,
  rumLib,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.generators) mkKeyValueDefault;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) nullOr path;

  inherit (rumLib.options) mkIntegrationOption;

  kittyKeyValue = pkgs.formats.keyValue {
    listsAsDuplicateKeys = true;
    mkKeyValue = mkKeyValueDefault {} " ";
  };

  cfg = config.rum.programs.kitty;
in {
  options.rum.programs.kitty = {
    enable = mkEnableOption "kitty";

    package = mkPackageOption pkgs "kitty" {};

    settings = mkOption {
      type = kittyKeyValue.type;
      default = {};
      example = {
        font_family = "RobotoMono";
      };
      description = ''
        Configuration written to {file}`$HOME/.config/kitty/kitty.conf`.
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
          Light theme to be linked to {file}`$HOME/.config/kitty/light-theme.auto.conf`.
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
          Dark theme to be linked to {file}`$HOME/.config/kitty/dark-theme.auto.conf`.
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
          no-preference theme to be linked to {file}`$HOME/.config/kitty/no-preference-theme.auto.conf`.
          This theme is set when your OS does not specify any theme preference.

          Please reference [kitty-themes' repository] for available themes.

          [kitty-themes' repository]: https://github.com/kovidgoyal/kitty-themes
        '';
      };
    };

    integrations = {
      fish.enable = mkIntegrationOption "kitty" "fish";
      zsh.enable = mkIntegrationOption "kitty" "zsh";
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files = {
      ".config/kitty/kitty.conf".source = mkIf (cfg.settings != {}) (
        kittyKeyValue.generate "kitty.conf" (
          cfg.settings
          // optionalAttrs (cfg.integrations.fish.enable || cfg.integrations.zsh.enable) {shell_integration = "no-rc";}
        )
      );
      ".config/kitty/light-theme.auto.conf".source = mkIf (cfg.theme.light != null) cfg.theme.light;
      ".config/kitty/dark-theme.auto.conf".source = mkIf (cfg.theme.dark != null) cfg.theme.dark;
      ".config/kitty/no-preference-theme.auto.conf".source = mkIf (cfg.theme.no-preference != null) cfg.theme.no-preference;
    };

    rum.programs.fish.config = mkIf cfg.integrations.fish.enable (
      mkAfter ''
        source ${cfg.package.shell_integration}/fish/vendor_conf.d/kitty-shell-integration.fish"
        set --prepend fish_complete_path ${cfg.package.shell_integration}/fish/vendor_completions.d"
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
