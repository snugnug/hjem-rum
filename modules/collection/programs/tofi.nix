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

    package = mkPackageOption pkgs "tofi" {};

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
        `${config.directory}/.config/tofi/config`.
        Please reference tofi(5) (manpage) at https://github.com/philj56/tofi/blob/master/doc/tofi.5.md,
        or see an example at https://github.com/philj56/tofi/blob/master/doc/config.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.".config/tofi/config".text = mkIf (cfg.settings != {}) (toKeyValue cfg.settings);
  };
}
