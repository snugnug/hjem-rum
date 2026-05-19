{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkAfter mkBefore mkIf;
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
        Configuration written to {file}`$XDG_CONFIG_HOME/direnv/direnv.toml`.
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
      fish.enable =
        mkEnableOption "direnv integration with fish"
        // {
          default = true;
          example = false;
        };
      nix-direnv = {
        enable =
          mkEnableOption "direnv integration with nix-direnv"
          // {
            default = true;
            example = false;
          };
        package = mkPackageOption pkgs "nix-direnv" {};
      };
      nushell.enable =
        mkEnableOption "direnv integration with nushell"
        // {
          default = true;
          example = false;
        };
      zsh.enable =
        mkEnableOption "direnv integration with zsh"
        // {
          default = true;
          example = false;
        };
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    xdg.config.files = {
      "direnv/direnv.toml" = mkIf (cfg.settings != {}) {
        source = toml.generate "direnv-config.toml" cfg.settings;
      };
      "direnv/direnvrc" = mkIf (cfg.direnvrc != "") {text = cfg.direnvrc;};
      "direnv/lib/nix-direnv.sh" = mkIf cfg.integrations.nix-direnv.enable {source = "${cfg.integrations.nix-direnv.package}/share/nix-direnv/direnvrc";};
    };

    rum.programs.fish.config = mkIf cfg.integrations.fish.enable (
      mkAfter "${getExe cfg.package} hook fish | source"
    );
    rum.programs.nushell.extraConfig = mkIf cfg.integrations.nushell.enable (
      # This worries me, because it may override $env.config.hooks.env_change.PWD if
      # the user sets it. That said, it is the way direnv suggests doing it, and
      # I cannot think of a better way. I have used mkBefore so that _this_ will
      # be overriden rather than the user's settings, but it is still imperfect.
      mkBefore ''
        $env.config.hooks.env_change.PWD = [
          { ||
              if (which direnv | is-empty) {
                return
              }

              direnv export json | from json | default {} | load-env
          }
        ]
      ''
    );
    rum.programs.zsh.initConfig = mkIf cfg.integrations.zsh.enable (
      mkAfter "eval \"$(${getExe cfg.package} hook zsh)\""
    );
  };
}
