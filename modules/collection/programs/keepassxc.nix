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

    package = mkPackageOption pkgs "keepassxc" {};

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
        Settings are written as an INI file to {file}`$HOME/.config/keepassxc/keepassxc.ini`.

        Please consult https://keepassxc.org/docs/KeePassXC_UserGuide, but also
        a configuration you create by toggling options through the GUI, as it
        doesn't seem they are documented.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.".config/keepassxc/keepassxc.ini".source = mkIf (cfg.settings != {}) (
      ini.generate "keepassxc.ini" cfg.settings
    );
  };
}
