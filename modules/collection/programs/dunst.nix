{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;

  ini = pkgs.formats.ini {};

  cfg = config.rum.programs.dunst;
in {
  options.rum.programs.dunst = {
    enable = mkEnableOption "dunst";

    package = mkPackageOption pkgs "dunst" {nullable = true;};

    settings = mkOption {
      type = ini.type;
      default = {};
      example = {
        global = {
          font = "Roboto Mono 8";
          frame_width = 2;
          offset = "(40,50)";
          origin = "top-right";
          separator_height = 2;
          sort = true;
          transparency = 0;
          width = 300;
        };
        urgency_low = {
          background = "\"#191919\"";
          foreground = "\"#BBBBBB\"";
        };
        urgency_normal = {
          background = "\"#191919\"";
          foreground = "\"#BBBBBB\"";
        };
        urgency_critical = {
          background = "\"#191919\"";
          foreground = "\"#DE6E7C\"";
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/.config/dunst/dunstrc`.
        Please reference [dunst's documentation] for config options.

        [dunst's documentation]: https://dunst-project.org/documentation
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."dunst/dunstrc" = mkIf (cfg.settings != {}) {
      source = ini.generate "dunstrc" cfg.settings;
    };
  };
}
