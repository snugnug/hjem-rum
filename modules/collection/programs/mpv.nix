{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) literalExpression mkEnableOption mkPackageOption mkOption mkIf optionalString mapAttrs' nameValuePair;
  inherit (lib.types) attrsOf listOf oneOf coercedTo either str number bool package;
  inherit (lib.generators) toKeyValue mkKeyValueDefault toINI;
  inherit (builtins) toString;

  cfg = config.rum.programs.mpv;

  mpvNum = coercedTo number toString str;
  mpvBool = coercedTo bool (value:
    if value
    then "yes"
    else "no")
  str;
  mpvTypes = oneOf [mpvNum mpvBool];

  mpvOption = either mpvTypes (listOf mpvTypes);
  mpvSection = attrsOf mpvOption;

  renderOptions = toKeyValue {listsAsDuplicateKeys = true;};
  renderProfiles = toINI {listsAsDuplicateKeys = true;};
  renderBindings = toKeyValue {mkKeyValue = mkKeyValueDefault {} " ";};
in {
  options.rum.programs.mpv = {
    enable = mkEnableOption "mpv";

    package = mkPackageOption pkgs "mpv" {nullable = true;};

    config = mkOption {
      description = ''
        Configuration converted and written to
        {file}`$XDG_CONFIG_HOME/mpv/mpv.conf`.

        See the manpage {manpage}`mpv(1)`
        for the full list of options.
      '';
      type = mpvSection;
      default = {};
      example = {
        autofit-larger = "100%x100%";
        hwdec = true;
        osd-playing-msg = "File: \${filename}";
      };
    };

    profiles = mkOption {
      description = ''
        Profiles converted and written to
        {file}`$XDG_CONFIG_HOME/mpv/mpv.conf`.

        See the manpage {manpage}`mpv(1)`
        for more information.
      '';
      type = attrsOf mpvSection;
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
      type = attrsOf mpvSection;
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
        else cfg.package.override {inherit (cfg) scripts;}
      )
    ];

    xdg.config.files =
      {
        "mpv/mpv.conf" = mkIf (cfg.config != {} || cfg.profiles != {}) {
          text = ''
            ${optionalString (cfg.config != {}) (renderOptions cfg.config)}
            ${optionalString (cfg.profiles != {}) (renderProfiles cfg.profiles)}
          '';
        };
        "mpv/input.conf" = mkIf (cfg.bindings != {}) {text = renderBindings cfg.bindings;};
      }
      // (mapAttrs' (
          name: value:
            nameValuePair "mpv/script-opts/${name}.conf" {
              text = renderOptions value;
            }
        )
        cfg.scriptOpts);
  };
}
