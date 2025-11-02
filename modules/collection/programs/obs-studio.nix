{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkPackageOption;

  cfg = config.rum.programs.obs-studio;
in {
  options.rum.programs.obs-studio = {
    enable = mkEnableOption "OBS Studio";

    package = mkPackageOption pkgs "obs-studio" {
      nullable = true;
      extraDescription = ''
        You can override the package to install plugins.
      '';
      example = ''
        # OBS has a special "package" to wrap the obs-studio package with plugins
        package = pkgs.wrapOBS.override { obs-studio = pkgs.obs-studio; } {
          # These plugins will get installed and wrapped into obs-studio for use
          plugins = with pkgs.obs-studio-plugins; [
            wlrobs
            waveform
            obs-websocket
          ];
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
  };
}
