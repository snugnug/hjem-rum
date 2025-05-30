{
  lib,
  config,
  pkgs,
  inputs,
  rumLib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkPackageOption mkOption optionalAttrs;
  inherit (rumLib.generators) toJson;
  inherit (rumLib.types) jsonType;
  inherit (lib.meta) getExe;

  cfg = config.rum.programs.hyprpanel;
in {
  options.rum.programs.hyprpanel = {
    enable = mkEnableOption "HyprPanel";

    package = mkPackageOption pkgs "hyprpanel" {};

    hyprland.enable = mkEnableOption "Enable Hyprland integration";

    settings = mkOption {
      type = jsonType;
      default = {};
      example = {
        "bar.layouts" = {
          "0" = {
            left = [ "dashboard" "workspaces" "windowtitle" ];
            middle = [ "media" ];
            right = [ "volume" "network" "bluetooth" "battery" "systray" "clock" "notifications" ];
          };
        };
      };
      description = ''
        JSON-style configuration for HyprPanel, written to
        {file}`$HOME/.config/hyprpanel/config.json`.
         Refer to [HyprPanel documentation](https://hyprpanel.com/configuration/settings.html).
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];

    # Integration with Hyprland exec-once 
    rum.programs.hyprland.settings.exec-once = mkIf cfg.hyprland.enable [ lib.getExe cfg.package ];

    # JSON config
    files.".config/hyprpanel/config.json".text = mkIf (cfg.settings != {}) (toJson {
      attrs = cfg.settings;
      indent = 2;
    });
  };
}
