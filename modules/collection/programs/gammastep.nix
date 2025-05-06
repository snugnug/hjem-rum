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

    package = mkPackageOption pkgs "gammastep" {};

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
        Settings are written as an INI file to {file}`$HOME/.config/gammastep/config.ini`.
        Refer to [gammastep's example configuration] all available options.

        [gammastep's example configuration]: https://gitlab.com/chinstrap/gammastep/-/blob/master/gammastep.conf.sample
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.".config/gammastep/config.ini".source = mkIf (cfg.settings != {}) (
      ini.generate "gammastep-config.ini" cfg.settings
    );
  };
}
