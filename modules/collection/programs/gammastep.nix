{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  ini = pkgs.formats.ini {};

  cfg = config.rum.programs.gammastep;
in {
  options.rum.programs.gammastep = {
    enable = mkEnableOption "gammastep";

    package = mkPackageOption pkgs "gammastep" {nullable = true;};

    settings = mkOption {
      type = ini.type;
      default = {};
      example = {
        general = {
          location-provider = "manual";
          temp-day = 5000;
        };

        manual = {
          lat = -12.5;
          lon = 55.6;
        };
      };
      description = ''
        Settings are written as an INI file to {file}`$XDG_CONFIG_HOME/gammastep/config.ini`.
        Refer to [gammastep's example configuration] all available options.

        [gammastep's example configuration]: https://gitlab.com/chinstrap/gammastep/-/blob/master/gammastep.conf.sample
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."gammastep/config.ini" = mkIf (cfg.settings != {}) {
      source = ini.generate "gammastep-config.ini" cfg.settings;
    };

    systemd.services.gammastep = {
      after = ["graphical-session.target"];
      description = "Screen color temperature manager";
      documentation = ["https://gitlab.com/chinstrap/gammastep"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = lib.getExe pkgs.gammastep;
        Restart = "on-failure";
      };
      wantedBy = ["graphical-session.target"];
    };
  };
}
