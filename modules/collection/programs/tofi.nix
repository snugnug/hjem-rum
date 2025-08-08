{
  config,
  lib,
  pkgs,
  rumLib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.generators) toKeyValue;
  inherit (rumLib.types) tofiSettingsType;

  cfg = config.rum.programs.tofi;
in {
  options.rum.programs.tofi = {
    enable = mkEnableOption "tofi";

    package = mkPackageOption pkgs "tofi" {nullable = true;};

    settings = mkOption {
      type = tofiSettingsType;
      default = {};
      example = {
        text-color = "#FFFFFF";
        num-results = 0;
        horizontal = false;
      };
      description = ''
        The configuration converted into "key = value" and written to
        {file}`$XDG_CONFIG_HOME/tofi/config`. Please reference
        {manpage}`tofi(5)`, or see an example at
        [tofi's default configuration].

        [tofi's default configuration]: https://github.com/philj56/tofi/blob/master/doc/config
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files."tofi/config".text = mkIf (cfg.settings != {}) (toKeyValue cfg.settings);
  };
}
