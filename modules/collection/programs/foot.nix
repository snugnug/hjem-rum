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

    package = mkPackageOption pkgs "foot" {nullable = true;};

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
        Settings are written as an INI file to {file}`$XDG_CONFIG_HOME/foot/foot.ini`.

        Refer to {manpage}`foot.ini(5)` or the [upstream template]
        for all available options.

        [upstream template]: https://github.com/aome510/spotify-player/blob/master/docs/config.md#themes
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."foot/foot.ini".source = mkIf (cfg.settings != {}) (
      ini.generate "foot.ini" cfg.settings
    );
  };
}
