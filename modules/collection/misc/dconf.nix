{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (builtins) toString;
  inherit (lib.generators) toINI;
  inherit (lib.gvariant) mkValue;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.rum.types) gvariantType;
  inherit (lib.types) attrsOf literalExpression;

  toDconfIni = toINI {mkKeyValue = mkIniKeyValue;};
  mkIniKeyValue = key: value: "${key}=${toString (mkValue value)}";

  cfg = config.rum.dconf;
in {
  options.rum.dconf = {
    enable = mkEnableOption "dconf module.";
    settings = mkOption {
      type = attrsOf (attrsOf gvariantType);
      default = {};
      example = literalExpression ''
        {
          "org/gnome/calculator" = {
            button-mode = "programming";
            show-thousands = true;
            base = 10;
            word-size = 64;
            window-position = lib.gvariant.mkTuple [100 100];
          };
        }
      '';
      description = ''
        Settings to write to the dconf configuration system.

        Note that the database is strongly-typed so you need to use the same types
        as described in the GSettings schema. For example, if an option is of type
        `uint32` (`u`), you need to wrap the number
        using the `lib.gvariant.mkUint32` constructor.
        Otherwise, since Nix integers are implicitly coerced to `int32`
        (`i`), it would get stored in the database as such, and GSettings
        might be confused when loading the setting.

        You might want to use [dconf2nix](https://github.com/gvolpe/dconf2nix)
        to convert dconf database dumps into compatible Nix expression.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.load-dconf = let
      iniFile = pkgs.writeText "dconf.ini" (toDconfIni cfg.settings);
      loadDconf = pkgs.writeShellScript "dconf-load" ''
        if [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
                export DCONF_DBUS_RUN_SESSION=""
              else
                export DCONF_DBUS_RUN_SESSION="${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon"
              fi

        $DCONF_DBUS_RUN_SESSION ${pkgs.dconf}/bin/dconf reset -f /
        $DCONF_DBUS_RUN_SESSION ${pkgs.dconf}/bin/dconf load / < ${iniFile}

        unset DCONF_DBUS_RUN_SESSION
      '';
    in {
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = loadDconf;
      };
    };
  };
}
