{
  lib,
  pkgs,
  osConfig,
  config,
  rumLib,
  ...
}: let
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.modules) mkIf mkRenamedOptionModule;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.strings) optionalString;
  inherit (lib.types) either lines listOf package path str;

  inherit (rumLib.attrsets) filterKeysPrefixes;
  inherit (rumLib.generators.environment) toEnvExport;
  inherit (rumLib.generators.hypr) toHyprconf pluginsToHyprconf;
  inherit (rumLib.types) hyprType;

  cfg = config.rum.desktops.hyprland;
in {
  imports = [(mkRenamedOptionModule ["rum" "programs" "hyprland"] ["rum" "desktops" "hyprland"])];

  options.rum.desktops.hyprland = {
    enable = mkEnableOption "Hyprland";

    settings = mkOption {
      type = hyprType;
      example = {
        "$mod" = "SUPER";
        decoration = {
          rounding = "3";
        };
      };
      default = {};
      description = ''
        Hyprland configuration written in Nix. Entries with the same key
        should be written as lists. Variables' and colors' names should be
        quoted. See [Hyprland's documentation] for more examples.

        [Hyprland's documentation]: https://wiki.hyprland.org
      '';
    };

    plugins = mkOption {
      type = listOf (either package path);
      default = [];
      description = ''
        List of Hyprland plugins to use. Can either be packages or
        absolute plugin paths.
      '';
    };

    importantPrefixes = mkOption {
      type = listOf str;
      default = ["$" "bezier" "name"];
      example = ["$" "bezier"];
      description = ''
        List of prefix of attributes to source at the top of the config.
      '';
    };

    extraConfig = mkOption {
      type = lines;
      default = "";
      description = ''
        Extra configuration that will be appended verbatim at the end of your `hyprland.conf`.
      '';
    };
  };

  config = let
    check = {
      plugins = cfg.plugins != [];
      settings = cfg.settings != {};
      variables = {
        noUWSM = config.environment.sessionVariables != {} && !osConfig.programs.hyprland.withUWSM;
        withUWSM = config.environment.sessionVariables != {} && osConfig.programs.hyprland.withUWSM;
      };
      extraConfig = cfg.extraConfig != "";
    };

    systemdSessionCommand = lib.concatStringsSep "; " [
      "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all"
      "systemctl --user stop hyprland-session.service"
      "systemctl --user start hyprland-session.service"
    ];
  in
    mkIf cfg.enable {
      xdg.config.files = {
        "hypr/hyprland.conf" = mkIf (check.plugins || check.settings || check.variables.noUWSM || check.extraConfig) {
          text =
            optionalString check.plugins (pluginsToHyprconf cfg.plugins cfg.importantPrefixes)
            + optionalString check.settings (toHyprconf {
              attrs = cfg.settings;
              inherit (cfg) importantPrefixes;
            })
            + optionalString check.variables.noUWSM (toHyprconf {
              attrs.env =
                # https://wiki.hyprland.org/Configuring/Environment-variables/#xdg-specifications
                [
                  "XDG_CURRENT_DESKTOP,Hyprland"
                  "XDG_SESSION_TYPE,wayland"
                  "XDG_SESSION_DESKTOP,Hyprland"
                ]
                ++ mapAttrsToList (key: value: "${key},${value}") config.environment.sessionVariables;
            })
            + optionalString (!osConfig.programs.hyprland.withUWSM) "exec-once = ${systemdSessionCommand}\n"
            + optionalString check.extraConfig cfg.extraConfig;
        };

        /*
        uwsm environment variables are advised to be separated
        (see https://wiki.hyprland.org/Configuring/Environment-variables/)
        */
        "uwsm/env" = mkIf check.variables.withUWSM {text = toEnvExport config.environment.sessionVariables;};

        "uwsm/env-hyprland" = let
          /*
          this is needed as we're using a predicate so we don't create an empty file
          (improvements are welcome)
          */
          filteredVars =
            filterKeysPrefixes ["HYPRLAND_" "AQ_"] config.environment.sessionVariables;
        in
          mkIf (check.variables.withUWSM && filteredVars != {})
          {text = toEnvExport filteredVars;};
      };

      /*
      since this is what home-manager does as well it is advised to disable systemd
      integration if the user is using uwsm
      we can just check if withUWSM is true and just not create the service
      (see https://wiki.hypr.land/Useful-Utilities/Systemd-start/#uwsm)
      */
      systemd.services.hyprland-session = mkIf (!osConfig.programs.hyprland.withUWSM) {
        description = "Hyprland compositor session";
        documentation = ["man:systemd.special(7)"];
        bindsTo = ["graphical-session.target"];
        wants = ["graphical-session-pre.target"];
        after = ["graphical-session-pre.target"];
      };
    };
}
