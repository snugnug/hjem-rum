{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) lines;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.direnv;
in {
  options.rum.programs.direnv = {
    enable = mkEnableOption "direnv";

    package = mkPackageOption pkgs "direnv" {nullable = true;};

    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
        global.warn_timeout = "0s";
        whitelist.prefix = ["~/src"];
      };
      description = ''
        Configuration written to {file}`$HOME/.config/direnv/direnv.toml`.
        Please reference [direnv's documentation] for config options.

        [direnv's documentation]: https://direnv.net/man/direnv.toml.1.html
      '';
    };

    direnvrc = mkOption {
      type = lines;
      default = "";
      example = ''
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        declare -A direnv_layout_dirs
        direnv_layout_dir() {
        	echo "''${direnv_layout_dirs[$PWD]:=$(
        		echo -n "$XDG_CACHE_HOME"/direnv/layouts/
        		echo -n "$PWD" | sha1sum | cut -d ' ' -f 1
        	)}"
        }
      '';
      description = ''
        Bash code loaded before every `.envrc`. Good for personal extensions.
        Find community-maintained examples in [direnv's wiki]

        [direnv's wiki]: https://github.com/direnv/direnv/wiki
      '';
    };

    integrations = {
      fish.enable = mkEnableOption "direnv integration with fish";
      nix-direnv = {
        enable =
          mkEnableOption "direnv integration with nix-direnv"
          // {
            default = true;
            example = false;
          };
        package = mkPackageOption pkgs "nix-direnv" {};
      };
      zsh.enable = mkEnableOption "direnv integration with zsh";
    };
  };

  config = let
    fishIntegration = optionalAttrs (config.rum.programs.fish.enable or false) {
      fish.config = mkIf cfg.integrations.fish.enable (
        mkAfter "${getExe cfg.package} hook fish | source"
      );
    };
    zshIntegration = optionalAttrs (config.rum.programs.zsh.enable or false) {
      zsh.initConfig = mkIf cfg.integrations.zsh.enable (
        mkAfter "eval \"$(${getExe cfg.package} hook zsh)\""
      );
    };
  in
    mkIf cfg.enable {
      packages = mkIf (cfg.package != null) [cfg.package];
      files = {
        ".config/direnv/direnv.toml".source = mkIf (cfg.settings != {}) (
          toml.generate "direnv-config.toml" cfg.settings
        );
        ".config/direnv/direnvrc".text = mkIf (cfg.direnvrc != "") cfg.direnvrc;
        ".config/direnv/lib/nix-direnv.sh".source = mkIf cfg.integrations.nix-direnv.enable "${cfg.integrations.nix-direnv.package}/share/nix-direnv/direnvrc";
      };
      rum.programs = fishIntegration // zshIntegration;
    };
}
