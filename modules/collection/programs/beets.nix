{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  yaml = pkgs.formats.yaml {};

  cfg = config.rum.programs.beets;
in {
  options.rum.programs.beets = {
    enable = mkEnableOption "beets";

    package =
      mkPackageOption pkgs "beets" {}
      // {
        extraDescription = ''
          To get plugins to work, you will need to override the beets derivation
          with the plugins you want:

          ```nix
          package = pkgs.beets.override {
              pluginOverrides = {
                  fish.enable = true;
                  convert.enable = true;
              };
          };
          ```

          Consult the [beets derivation][beets-derivation] for a list of available plugins.

          [beets-derivation]: https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/audio/beets/builtin-plugins.nix
        '';
      };

    settings = mkOption {
      inherit (yaml) type;
      default = {};
      description = ''
        Beets configuration that is written to {file}`$HOME/.config/beets/config.yaml`.
        Refer to the beets [documentation] for available options.

        If you would like to use plugins, please consult the description of
        [rum.programs.beets.package](#option-rum-programs-beets-package) and the official
        [documentation][plugin-doc] on the plugins configuration.

        [documentation]: https://beets.readthedocs.io/en/stable/reference/config.html
        [plugin-doc]: https://beets.readthedocs.io/en/stable/reference/config.html#plugins

      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.".config/beets/config.yaml".source = mkIf (cfg.settings != {}) (
      yaml.generate "config.yaml" cfg.settings
    );
  };
}
