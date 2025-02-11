{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) attrsOf either int str lines;
  inherit (lib.generators) toKeyValue;

  cfg = config.rum.programs.ncmpcpp;
in {
  options.rum.programs.ncmpcpp = {
    enable = mkEnableOption "ncmpcpp";

    package = mkPackageOption pkgs "ncmpcpp" {};

    settings = mkOption {
      type = attrsOf (either int str);
      default = {};
      example = {
        mpd_host = "localhost";
        mpd_port = "6600";
        mpd_music_dir = "~/music";
      };

      description = ''
        Configuration written to `${config.directory}/.config/ncmpcpp/config`.
        Please reference ncmpcpp(1) (ncmpcpp's man page) to configure it accordingly, or access
        https://github.com/ncmpcpp/ncmpcpp/blob/master/doc/config for an example.
      '';
    };

    bindings = mkOption {
      type = lines;
      default = "";
      example = ''
        def_key "p"
          pause

        def key "q"
          quit
      '';

      description = ''
        Custom bindings configuration written to `${config.directory}/.config/ncmpcpp/bindings`.
        Please reference ncmpcpp(1) (ncmpcpp's man page) to configure it accordingly, or access
        https://github.com/ncmpcpp/ncmpcpp/blob/master/doc/bindings for an example.
      '';
    };

    withVisualizer = mkEnableOption {
      description = "Defines whether to enable ncmpcpp's visualizer.";
    };
  };

  config = mkIf cfg.enable {
    packages = [
      (cfg.package.override {
        visualizerSupport = cfg.withVisualizer;
      })
    ];
    files.".config/ncmpcpp/config".text = toKeyValue {} cfg.settings;
    files.".config/ncmpcpp/bindings".text = cfg.bindings;
  };
}
