{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.meta) getExe;

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
        Settings are written as an <format> file to {file}`$HOME/.config/path/to/hyprpanel.<format>`.
        Refer to [Hyprpanel's documentation] to see all available options.
        
        [Hyprpanel's documentation]: https://hyprpanel.com/configuration/panel.html
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
          Alternative config input (overrides settings if set).
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];

    # Integration with Hyprland exec-once 
    rum.programs.hyprland.settings.exec-once = mkIf cfg.hyprland.enable [
      getExe cfg.package
    ];

    files = {
      ".config/hyprpanel/config.json".source = mkIf (cfg.settings != {}) (
        json.generate "hyprpanel-config.json"
         (cfg.settings // cfg.override)
       );
    };
  };
}
