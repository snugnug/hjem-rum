{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  ini = pkgs.formats.ini {};

  cfg = config.rum.programs.flameshot;
in {
  options.rum.programs.flameshot = {
    enable = mkEnableOption "flameshot";

    package = mkPackageOption pkgs "flameshot" {nullable = true;};

    settings = mkOption {
      type = ini.type;
      default = {};
      example = {
        General = {
          disabledTrayIcon = true;
          saveLastRegion = true;
          showDesktopNotification = false;
          showStartupLaunchMessage = false;
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/flameshot/flameshot.ini`.
        Please reference [flameshot's example config] for config options.

        [flameshot's example config]: https://github.com/flameshot-org/flameshot/blob/master/flameshot.example.ini
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."flameshot/flameshot.ini" = mkIf (cfg.settings != {}) {
      source = ini.generate "flameshot.ini" cfg.settings;
    };
  };
}
