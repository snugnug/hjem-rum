{
  lib,
  pkgs,
  config,
  rumLib,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkPackageOption;

  inherit (rumLib.options) mkIntegrationOption;

  cfg = config.rum.programs.fzf;
in {
  options.rum.programs.fzf = {
    enable = mkEnableOption "fzf";

    package = mkPackageOption pkgs "fzf" {};

    integrations = {
      fish.enable = mkIntegrationOption "fzf" "fish";
      zsh.enable = mkIntegrationOption "fzf" "zsh";
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];

    rum.programs.fish.config = mkIf cfg.integrations.fish.enable (
      mkAfter "${getExe cfg.package} --fish | source"
    );
    rum.programs.zsh.initConfig = mkIf cfg.integrations.zsh.enable (
      mkAfter "source <(${getExe cfg.package} --zsh)"
    );
  };
}
