{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkPackageOption;

  cfg = config.rum.programs.nix-your-shell;
in {
  options.rum.programs.nix-your-shell = {
    enable = mkEnableOption "nix-your-shell";

    package = mkPackageOption pkgs "nix-your-shell" {nullable = true;};

    integrations = {
      fish.enable =
        mkEnableOption "nix-your-shell integration with fish"
        // {
          default = true;
          example = false;
        };
      nushell.enable =
        mkEnableOption "nix-your-shell integration with nushell"
        // {
          default = true;
          example = false;
        };
      zsh.enable =
        mkEnableOption "nix-your-shell integration with zsh"
        // {
          default = true;
          example = false;
        };
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];

    rum.programs.fish.config = mkIf cfg.integrations.fish.enable (
      mkAfter "${getExe cfg.package} fish | source"
    );
    rum.programs.zsh.initConfig = mkIf cfg.integrations.zsh.enable (
      mkAfter "${getExe cfg.package} zsh | source /dev/stdin"
    );
    rum.programs.nushell.extraConfig = mkIf cfg.integrations.nushell.enable (
      mkAfter ''
        source ${
          pkgs.runCommand "nix-your-shell-init-nu" {} ''
            ${getExe cfg.package} nu >> "$out"
          ''
        }
      ''
    );
  };
}
