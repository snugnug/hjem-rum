{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) attrsOf listOf oneOf int str bool;
  inherit (lib.rum.generators.ncmpcpp) toNcmpcppBinding toNcmpcppSettings;
  inherit (lib.rum.types) ncmpcppBindingType;

  cfg = config.rum.programs.ncmpcpp;
in {
  options.rum.programs.ncmpcpp = {
    enable = mkEnableOption ''
      Enables the rum module for ncmpcpp, a mpd-based music player.
    '';

    package = mkPackageOption pkgs "ncmpcpp" {
      extraDescription = ''
        You can use an override to toggle certain features like the visualizer, a clock screen, and more.
               Please check out the package source for a complete list.
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
        Configuration written to `${config.directory}/.config/ncmpcpp/config`.
        Please reference ncmpcpp(1) (ncmpcpp's man page) to configure it accordingly, or access
        https://github.com/ncmpcpp/ncmpcpp/blob/master/doc/config for an example.
      '';
    };

    bindings = mkOption {
      type = attrsOf (listOf ncmpcppBindingType);
      default = {};
      description = ''
               Custom bindings configuration written to `${config.directory}/.config/ncmpcpp/bindings`.
               Please reference ncmpcpp(1) (ncmpcpp's man page) to configure it accordingly, or access
               https://github.com/ncmpcpp/ncmpcpp/blob/master/doc/bindings for an example.

        The lists are separated between keys, for actions ran on keypresses, and commands, for
        actions ran on commands. The option's example demonstrates this greatly.
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
    packages = [cfg.package];
    files = {
      ".config/ncmpcpp/config".text = mkIf (cfg.settings != {}) (toNcmpcppSettings cfg.settings);
      ".config/ncmpcpp/bindings".text = mkIf (cfg.bindings != {}) (toNcmpcppBinding cfg.bindings);
    };
  };
}
