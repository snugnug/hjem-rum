{
  config,
  lib,
  pkgs,
  rumLib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) attrsOf listOf oneOf int str bool;
  inherit (rumLib.generators.ncmpcpp) toNcmpcppBinding toNcmpcppSettings;
  inherit (rumLib.types) ncmpcppBindingType;

  cfg = config.rum.programs.ncmpcpp;
in {
  options.rum.programs.ncmpcpp = {
    enable = mkEnableOption "ncmpcpp, a mpd-based music player.";

    package = mkPackageOption pkgs "ncmpcpp" {
      nullable = true;
      extraDescription = ''
        You can override the package to customize certain settings that are baked into the package.
      '';
      example = ''
        pkgs.ncmpcpp.override {
          # useful overrides in the package
          outputsSupport = true; # outputs screen
          visualizerSupport = false; # visualizer screen
          clockSupport = true; # clock screen
          taglibSupport = true; # tag editor
        };
      '';
    };

    settings = mkOption {
      type = attrsOf (oneOf [int str bool]);
      default = {};
      example = {
        mpd_host = "localhost";
        mpd_port = 6600;
        mpd_music_dir = "~/music";
        statusbar_visibility = true;
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/ncmpcpp/config`.
        Please reference {manpage}`ncmpcpp(1)` to configure it accordingly, or consult [ncmpcpp's example configuration].

        [ncmpcpp's example configuration]: https://github.com/ncmpcpp/ncmpcpp/blob/master/doc/config
      '';
    };

    bindings = mkOption {
      type = attrsOf (listOf ncmpcppBindingType);
      default = {};
      description = ''
        Custom bindings configuration written to {file}`$XDG_CONFIG_HOME/ncmpcpp/bindings`.
        Please reference {manpage}`ncmpcpp(1)` to configure it accordingly, or consult
        [ncmpcpp's example bindings file].

        The lists are separated between keys, for actions ran on keypresses, and commands, for actions ran
        on commands. The option's example demonstrates this greatly.

        [ncmpcpp's example bindings file]: https://github.com/ncmpcpp/ncmpcpp/blob/master/doc/bindings
      '';
      example = {
        keys = [
          {
            binding = "ctrl-q";
            actions = ["stop" "quit"];
          }
          {
            binding = "q";
            actions = ["quit"];
            deferred = true;
          }
        ];
        commands = [
          {
            binding = "!sq";
            actions = ["stop" "quit"];
          }
          {
            binding = "!q";
            actions = ["quit"];
            deferred = true;
          }
        ];
      };
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files = {
      "ncmpcpp/config".text = mkIf (cfg.settings != {}) (toNcmpcppSettings cfg.settings);
      "ncmpcpp/bindings".text = mkIf (cfg.bindings != {}) (toNcmpcppBinding cfg.bindings);
    };
  };
}
