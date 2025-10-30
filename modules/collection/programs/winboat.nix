{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  json = pkgs.formats.json {};

  cfg = config.rum.programs.winboat;
in {
  options.rum.programs.winboat = {
    enable = mkEnableOption "WinBoat";

    package = mkPackageOption pkgs "winboat" {nullable = true;};

    settings = mkOption {
      inherit (json) type;
      default = {};
      example = {
        customApps = [
          {
            Name = "Bob's favourite app";
            Path = "C:\\Users\\bob\\Downloads\\App\\app.exe";
            Source = "custom";
          }
        ];
        experimentalFeatures = true;
        rdpMonitoringEnabled = false;
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/winboat/winboat.config.json`.
        As of writing, there aren't any docs for the available configuration options,
        but please refer the configuration types in [this file] for config options.

        [this file]: https://github.com/TibixDev/winboat/blob/main/src/renderer/lib/config.ts
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];

    xdg.config.files."winboat/winboat.config.json" = mkIf (cfg.settings != {}) {
      source = json.generate "winboat-config.json" cfg.settings;
    };
  };
}
