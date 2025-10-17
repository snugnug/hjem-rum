{
  lib,
  config,
  pkgs,
  rumLib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkPackageOption mkOption;
  inherit (rumLib.generators.hypr) toHyprconf;
  inherit (rumLib.types) hyprType;

  cfg = config.rum.programs.hypridle;
in {
  options.rum.programs.hypridle = {
    enable = mkEnableOption "hypridle";

    package = mkPackageOption pkgs "hypridle" {nullable = true;};

    settings = mkOption {
      type = hyprType;
      default = {};
      example = {
        general = {
          lock_cmd = "notify-send \"lock!\"";
          unlock_cmd = "notify-send \"unlock!\"";
          before_sleep_cmd = "notify-send \"Zzz\"";
          after_sleep_cmd = "notify-send \"Awake!\"";
          ignore_dbus_inhibit = false;
          ignore_systemd_inhibit = false;
        };

        listener = [
          {
            timeout = 500;
            on-timeout = "notify-send \"You are idle!\"";
            on-resume = "notify-send \"Welcome back!\"";
          }
        ];
      };
      description = ''
        Is written to {file}`$HOME/hypr/hypridle.conf`.

        Configuration options can be found on the [Hyprland Wiki].

        [Hyprland Wiki]: https://wiki.hyprland.org/Hypr-Ecosystem/hypridle
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."hypr/hypridle.conf" = mkIf (cfg.settings != {}) {
      text = toHyprconf {
        attrs = cfg.settings;
      };
    };
  };
}
