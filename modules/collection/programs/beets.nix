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
    enable =
      mkEnableOption "beets"
      // {
        extraDescription = ''
          To get plugins to work, you will need to override the beets derivation
          with the plugins you want:

          ```nix
          pkgs.beets.override {
              pluginOverrides = {
                  fish.enable = true;
                  convert.enable = true;
              };
          };
          ```

          Additionally, you will have to tell beets about the plugins to load.
          This can be done by passing a list containing their names to
          `rum.programs.beets.settings.plugins`. Consult the [documentation] for more information.

          [documentation]: https://beets.readthedocs.io/en/stable/reference/config.html#plugins
        '';
      };
    package = mkPackageOption pkgs "beets" {};
    settings = mkOption {
      inherit (yaml) type;
      default = {};
      description = ''
        Beets configuration that is written to `.config/beets/config.yaml`.
        Refer to the beets [documentation] for available options.

        Regarding plugins, please consult the description of [rum.programs.beets.enable](#option-rum-programs-beets-enable).

        [documentation]: https://beets.readthedocs.io/en/stable/reference/config.html
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
