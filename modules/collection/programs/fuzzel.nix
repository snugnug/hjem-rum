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

    package = mkPackageOption pkgs "fuzzel" {nullable = true;};

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

        Please reference {manpage}`fuzzel.ini(5)` for configuration options.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."fuzzel/fuzzel.ini".source = mkIf (cfg.settings != {}) (
      ini.generate "fuzzel.ini" cfg.settings
    );
  };
}
