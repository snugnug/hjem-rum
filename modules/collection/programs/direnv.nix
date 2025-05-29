{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) lines;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.direnv;
in {
  options.rum.programs.direnv = {
    enable = mkEnableOption "direnv";

    package = mkPackageOption pkgs "direnv" {};

    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
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
        enable = mkEnableOption "direnv integration with nix-direnv";
        package = mkPackageOption pkgs "nix-direnv" {};
      };
      zsh.enable = mkEnableOption "direnv integration with zsh";
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files = {
      ".config/direnv/direnv.toml".source = mkIf (cfg.settings != {}) (
        toml.generate "direnv-config.toml" cfg.settings
      );
      ".config/direnv/direnvrc".text = mkIf (cfg.direnvrc != "") cfg.direnvrc;
      ".config/direnv/lib/nix-direnv.sh".source = mkIf cfg.integrations.nix-direnv.enable "${cfg.integrations.nix-direnv.package}/share/nix-direnv/direnvrc";
    };

    rum.programs.fish.config = mkIf cfg.integrations.fish.enable ''
      ${getExe cfg.package} hook fish | source
    '';
    rum.programs.zsh.initConfig = mkIf cfg.integrations.zsh.enable ''
      eval "$(${getExe cfg.package} hook zsh)"
    '';
  };
}
