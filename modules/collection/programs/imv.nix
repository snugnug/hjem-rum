{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  ini = pkgs.formats.ini {};

  cfg = config.rum.programs.imv;

  optionsFile = ini.generate "imv-options.ini" {
    options = cfg.settings.options or {};
  };
  aliasesFile = ini.generate "imv-aliases.ini" {
    aliases = cfg.settings.aliases or {};
  };
  bindsFile = ini.generate "imv-binds.ini" {
    binds = cfg.settings.binds or {};
  };
in {
  options.rum.programs.imv = {
    enable = mkEnableOption "imv";

    package = mkPackageOption pkgs "imv" {nullable = true;};

    settings = mkOption {
      type = ini.type;
      default = {};
      example = {
        options.background = "ffffff";
        aliases.x = "close";
      };
      description = ''
        Settings are written as an INI file to {file}`$XDG_CONFIG_HOME/imv/config`.
        The lists are separated between options, aliases, and binds.
        Please reference {manpage}`IMV(5)` to configure it accordingly.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."imv/config" = mkIf (cfg.settings != {}) {
      source = pkgs.concatText "imv-config.ini" [
        optionsFile
        aliasesFile
        bindsFile
      ];
    };
  };
}
