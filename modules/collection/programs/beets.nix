{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption literalExample;

  yaml = pkgs.formats.yaml {};

  cfg = config.rum.programs.beets;
in {
  options.rum.programs.beets = {
    enable = mkEnableOption "beets";

    package = mkPackageOption pkgs "beets" {
      nullable = true;
      extraDescription = ''
        To get plugins to work, you will need to override the beets derivation
        with the plugins you want. Consult the [beets derivation] for a list of
        available plugins.

        [beets derivation]: https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/audio/beets/builtin-plugins.nix
      '';
      example = ''
        pkgs.beets.override {
            pluginOverrides = {
                fish.enable = true;
                convert.enable = true;
            };
        };
      '';
    };

    settings = mkOption {
      inherit (yaml) type;
      default = {};
      description = ''
        Beets configuration that is written to {file}`$XDG_CONFIG_HOME/beets/config.yaml`.
        Refer to the beets [documentation] for available options.

        If you would like to use plugins, please consult the description of
        [rum.programs.beets.package](#option-rum-programs-beets-package) and the
        [official plugin documentation] on the plugins configuration.

        [documentation]: https://beets.readthedocs.io/en/stable/reference/config.html
        [official plugin documentation]: https://beets.readthedocs.io/en/stable/reference/config.html#plugins
      '';
      example = {
        plugins = "fish convert chroma";
        directory = "/mnt/music";
        library = "/mnt/music/library.db";
        per_disc_numbering = "yes";
        asciify_paths = true;
        convert = {
          auto = "yes";
          format = "flac";
          never_convert_lossy_files = "yes";
        };
        import = {
          incremental = "yes";
          bell = "yes";
          languages = "en";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."beets/config.yaml" = mkIf (cfg.settings != {}) {
      source = yaml.generate "config.yaml" cfg.settings;
    };
  };
}
