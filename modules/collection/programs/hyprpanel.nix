{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  json = pkgs.formats.json {};

  cfg = config.rum.programs.hyprpanel;
in {
  options.rum.programs.hyprpanel = {
    enable = mkEnableOption "HyprPanel";

    package = mkPackageOption pkgs "hyprpanel" {};

    hyprland.enable = mkEnableOption "Enable Hyprland integration";

    settings = mkOption {
      type = json.type;
      default = {};
      example = {
         bar.layouts = {
          "0" = {
            left = ["dashboard" "workspaces" "windowtitle"];
            middle = ["media"];
            right = ["volume" "network" "bluetooth" "battery" "systray" "clock" "notifications"];
          };
        };
        theme.bar.scaling = 85;
        scalingPriority = "both";
        tear = true;
        menus.transition = "crossfade";
        theme.notification.scaling = 80;  
      };
      description = ''
        JSON-style configuration for HyprPanel, written to
        {file}`$HOME/.config/hyprpanel/config.json`.

        Refer to [HyprPanel documentation](https://hyprpanel.com/configuration/settings.html).
      '';
    };

    override = mkOption {
      type = json.type;
      default = {};
      example = {
        "theme.notification.background" = "#181826";
        "theme.notification.close_button.background" = "#f38ba7";
        "theme.bar.buttons.clock.icon" = "#11111b";
        "theme.bar.buttons.clock.text" = "#cdd6f4";
      };
      description = ''
        Additional theme values for overriding default themes.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];

    # Integration with Hyprland exec-once 
    rum.programs.hyprland.settings.exec-once = mkIf cfg.hyprland.enable [
      lib.getExe cfg.package
    ];

    files = {
      ".config/hyprpanel/config.json".source = mkIf (cfg.settings != {}) (
        json.generate "hyprpanel-config.json"
         (cfg.settings // cfg.override)
       );
    };
  };
}
