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
    rum.programs.hyprland.settings.exec-once = mkIf cfg.hyprland.enable [
      lib.getExe cfg.package
    ];

    files = {
      ".config/hyprpanel/config.json".source = mkIf (cfg.settings != {}) (
        json.generate "hyprpanel-config.json" cfg.settings
      );
    };
  };
}
