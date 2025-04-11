{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) enum;

  gitIni = pkgs.formats.gitIni {};
  cfg = config.rum.programs.git;
in {
  options.rum.programs.git = {
    enable = mkEnableOption "git";

    package = mkPackageOption pkgs "git" {};

    settings = mkOption {
      type = gitIni.type;
      default = {};
      example = {
        user = {
          email = "alice@example.com";
          name = "alice";
        };
        init = {
          defaultBranch = "main";
        };
        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
      };
      description = ''
        Settings that will be written to your configuration file.
      '';
    };

    destination = mkOption {
      type = enum [
        ".gitconfig"
        ".config/git/config"
      ];
      default = ".gitconfig";
      description = ''
        Select your preferred git config location. Do note that options set in
        {file}`$HOME/.gitconfig` will shadow anything set in `.config/git/config`.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files.${cfg.destination}.source = mkIf (cfg.settings != {}) (
      gitIni.generate ".gitconfig" cfg.settings
    );
  };
}
