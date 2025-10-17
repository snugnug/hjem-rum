{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  ini = pkgs.formats.ini {};

  cfg = config.rum.programs.keepassxc;
in {
  options.rum.programs.keepassxc = {
    enable = mkEnableOption "KeePassXC";

    package = mkPackageOption pkgs "keepassxc" {nullable = true;};

    settings = mkOption {
      type = ini.type;
      default = {};
      example = {
        General = {
          BackupBeforeSave = true;
          ConfigVersion = 2;
        };
        GUI = {
          ColorPasswords = true;
          MinimizeOnClose = true;
          MinimizeOnStartup = true;
          MinimizeToTray = true;
          ShowTrayIcon = true;
          TrayIconAppearance = "colorful";
        };
      };
      description = ''
        Settings are written as an INI file to {file}`$XDG_CONFIG_HOME/keepassxc/keepassxc.ini`. Please reference
        [KeePassXC's User Guide].

        It also can be configured by toggling options through the GUI, but this does not seem documented.

        [KeePassXC's User Guide]: https://keepassxc.org/docs/KeePassXC_UserGuide
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."keepassxc/keepassxc.ini" = mkIf (cfg.settings != {}) {
      source = ini.generate "keepassxc.ini" cfg.settings;
    };
  };
}
