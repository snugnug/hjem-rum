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

    package = mkPackageOption pkgs "flameshot" {};

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
        Configuration written to {file}`$HOME/.config/flameshot/flameshot.ini`.
        Please reference [flameshot's example config] for config options.

        [flameshot's example config]: https://github.com/flameshot-org/flameshot/blob/master/flameshot.example.ini
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.".config/flameshot/flameshot.ini".source = mkIf (cfg.settings != {}) (
      ini.generate "flameshot.ini" cfg.settings
    );
  };
}
