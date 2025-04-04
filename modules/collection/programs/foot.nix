{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  ini = pkgs.formats.ini {};

  cfg = config.rum.programs.foot;
in {
  options.rum.programs.foot = {
    enable = mkEnableOption "foot";

    package = mkPackageOption pkgs "foot" {};

    settings = mkOption {
      type = ini.type;
      default = {};
      example = {
        main = {
          term = "xterm-256color";

          font = "NotoSansM Nerd Font Mono:size=13";
        };

        mouse = {
          hide-when-typing = "yes";
        };

        colors = {
          alpha = 0.8;
        };

        scrollback = {
          lines = 90000;
          indicator-position = "none";
        };
      };
      description = ''
        Settings are written as an INI file to ''${config.directory}/.config/foot/foot.ini.

        Refer to https://codeberg.org/dnkl/foot/src/branch/master/foot.ini for
        all available options.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.".config/foot/foot.ini".source = mkIf (cfg.settings != {}) (
      ini.generate "foot.ini" cfg.settings
    );
  };
}
