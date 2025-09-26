{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) generators literalExpression mkIf mkOption;
  inherit (lib.types) oneOf attrsOf listOf str int bool float package;
  inherit (builtins) typeOf;

  cfg = config.rum.programs.mpv;

  mpvOptions = let
    opt =
      oneOf [str int bool float (listOf opt)];
  in
    attrsOf opt;

  renderOption = option: let
    optT = typeOf option;
  in
    if optT == "int" || optT == "float"
    then toString option
    else if optT == "bool"
    then
      if option
      then "yes"
      else "no"
    else option;

  renderOptions = generators.toKeyValue {
    mkKeyValue = generators.mkKeyValueDefault {mkValueString = renderOption;} "=";
    listsAsDuplicateKeys = true;
  };

  renderProfiles = generators.toINI {
    mkKeyValue = generators.mkKeyValueDefault {mkValueString = renderOption;} "=";
    listsAsDuplicateKeys = true;
  };

  renderBindings = bindings: lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name} ${value}") bindings);
in {
  options.rum.programs.mpv = {
    enable = lib.mkEnableOption "mpv";

    package = lib.mkPackageOption pkgs "mpv" {nullable = true;};

    config = mkOption {
      description = ''
        Configuration converted and written to
        {file}`$XDG_CONFIG_HOME/mpv/mpv.conf`.

        See the manpage {manpage}`mpv(1)`
        for the full list of options.
      '';
      type = mpvOptions;
      default = {};
      example = {
        autofit-larger = "100%x100%";
        hwdec = true;
        osd-playing-msg = "File: $\{filename}";
      };
    };

    profiles = mkOption {
      description = ''
        Profiles converted and written to
        {file}`$XDG_CONFIG_HOME/mpv/mpv.conf`.

        See the manpage {manpage}`mpv(1)`
        for more information.
      '';
      type = attrsOf mpvOptions;
      default = {};
      example = {
        big-cache = {
          cache = true;
          demuxer-max-bytes = "512Mib";
          demuxer-readhead-secs = 20;
        };
        reduce-judder = {
          video-sync = "display-resample";
          interpolation = true;
        };
      };
    };

    bindings = mkOption {
      description = ''
        Inputs converted and written to
        {file}`$XDG_CONFIG_HOME/mpv/input.conf`.

        See the manpage {manpage}`mpv(1)`
        for more information.
      '';
      type = attrsOf str;
      default = {};
      example = {
        WHEEL_UP = "seek 10";
        WHEEL_DOWN = "seek -10";
        "Alt+0" = "set window-scale 0.5";
      };
    };

    scripts = mkOption {
      type = listOf package;
      default = [];
      example = literalExpression "with pkgs.mpvScripts; [ sponsorblock mpris ]";
      description = ''
        List of scripts to use with mpv.
      '';
    };

    scriptOpts = mkOption {
      description = ''
        Script options converted and written to
        {file}`$XDG_CONFIG_HOME/mpv/script-opts/<name>.conf`.

        See the manpage {manpage}`mpv(1)`
        for the full list of options of builtin scripts.
      '';
      type = attrsOf mpvOptions;
      default = {};
      example = {
        osc = {
          scalewindowed = 2.0;
          vidscale = false;
          visibility = "always";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    packages = [
      (
        if cfg.scripts == []
        then cfg.package
        else pkgs.mpv.override {inherit (cfg) scripts;}
      )
    ];

    xdg.config.files =
      {
        "mpv/mpv.conf".text = mkIf (cfg.config != {} || cfg.profiles != {}) ''
          ${lib.optionalString (cfg.config != {}) (renderOptions cfg.config)}
          ${lib.optionalString (cfg.profiles != {}) (renderProfiles cfg.profiles)}
        '';
        "mpv/input.conf".text =
          mkIf (cfg.bindings != {}) (renderBindings cfg.bindings);
      }
      // (lib.mapAttrs' (
          name: value:
            lib.nameValuePair "mpv/script-opts/${name}.conf" {
              text = renderOptions value;
            }
        )
        cfg.scriptOpts);
  };
}
