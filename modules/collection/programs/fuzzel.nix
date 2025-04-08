{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.modules) mkIf;

  ini = pkgs.formats.ini {};

  cfg = config.rum.programs.fuzzel;
in {
  options.rum.programs.fuzzel = {
    enable = mkEnableOption "fuzzel";

    package = mkPackageOption pkgs "fuzzel" {};

    settings = mkOption {
      type = ini.type;
      default = {};
      example = {
        main = {
          terminal = "foot";
          layer = "overlay";
        };
        colors.background = "ffffffff";
      };
      description = ''
        Is written to {file}`$HOME/fuzzel/fuzzel.ini`.

        Consult [man 5 fuzzel.ini](https://www.mankier.com/5/fuzzel.ini).
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.".config/fuzzel/fuzzel.ini".source = mkIf (cfg.settings != {}) (
      ini.generate "fuzzel.ini" cfg.settings
    );
  };
}
