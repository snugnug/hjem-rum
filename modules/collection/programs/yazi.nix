{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) isPath;

  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption literalExpression;
  inherit (lib.types) attrsOf nullOr either path lines package;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.yazi;
in {
  options.rum.programs.yazi = {
    enable = mkEnableOption "yazi file manager";

    package = mkPackageOption pkgs "yazi" {nullable = true;};

    settings = mkOption {
      inherit (toml) type;
      default = {};
      example = {
        mgr = {
          show_hidden = true;
        };
      };
      description = ''
        The configurations converted to TOML and written to {file}`$XDG_CONFIG_HOME/yazi/yazi.toml`.
        Please reference [yazi's configuration documentation] for configuration options.

        [yazi's configuration documentation]: https://yazi-rs.github.io/docs/configuration/yazi
      '';
    };

    keymap = mkOption {
      inherit (toml) type;
      default = {};
      example = {
        mgr.prepend_keymap = [
          {
            on = "<C-a>";
            run = "my-cmd1";
            desc = "Single command with `Ctrl + a`";
          }
        ];
      };
      description = ''
        The keymap configurations converted to TOML and written to {file}`$XDG_CONFIG_HOME/yazi/keymap.toml`.
        Please reference [yazi's keymap configuration documentation] for configuration options.

        [yazi's keymap configuration documentation]: https://yazi-rs.github.io/docs/configuration/keymap
      '';
    };

    theme = mkOption {
      inherit (toml) type;
      default = {};
      example = {
        flavor = {
          dark = "dracula";
          light = "gruvbox";
        };
      };
      description = ''
        The keymap configurations converted to TOML and written to {file}`$XDG_CONFIG_HOME/yazi/theme.toml`.
        Please reference [yazi's theming configuration documentation] for configuration options.

        [yazi's theming configuration documentation]: https://yazi-rs.github.io/docs/configuration/theme
      '';
    };

    initLua = mkOption {
      type = nullOr (either lines path);
      default = null;
      example = literalExpression "./init.lua";
      description = ''
        The `init.lua` file written to {file}`$XDG_CONFIG_HOME/yazi/init.lua`.
        Please reference [yazi's plugins documentation] to get a better understanding the the file's usage.

        [yazi's plugins documentation]: https://yazi-rs.github.io/docs/plugins/overview/
      '';
    };

    plugins = mkOption {
      type = attrsOf (either path package);
      default = {};
      example = literalExpression ''
        {
          foo = ./foo;
          git = pkgs.yaziPlugins.git;
        };
      '';
      description = ''
        A list of plugins for Yazi, which is placed in the {file}`$XDG_CONFIG_HOME/yazi/plugins/` folder.
        Please reference [yazi's plugins documentation] to get a better understanding of plugins.

        [yazi's plugins documentation]: https://yazi-rs.github.io/docs/plugins/overview/
      '';
    };

    flavors = mkOption {
      type = attrsOf (either path package);
      default = {};
      example = literalExpression ''
        {
          foo = ./foo;
          bar = fetchFromGitHub { ... };
        };
      '';
      description = ''
        A list of "flavors", or pre-made themes for Yazi, which is placed in the {file}`$XDG_CONFIG_HOME/yazi/flavors` folder.
        Please reference [yazi's flavors documentation] to get a better understanding of flavors.

        [yazi's flavors documentation]: https://yazi-rs.github.io/docs/flavors/overview
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];

    xdg.config.files =
      {
        "yazi/yazi.toml" = mkIf (cfg.settings != {}) {
          source = toml.generate "yazi-config.toml" cfg.settings;
        };
        "yazi/keymap.toml" = mkIf (cfg.keymap != {}) {
          source = toml.generate "yazi-keymap-config.toml" cfg.keymap;
        };
        "yazi/theme.toml" = mkIf (cfg.theme != {}) {
          source = toml.generate "yazi-theme-config.toml" cfg.theme;
        };
        "yazi/init.lua" = mkIf (cfg.initLua != null) (
          if isPath cfg.initLua
          then {source = cfg.initLua;}
          else {text = cfg.initLua;}
        );
      }
      // (mapAttrs' (name: plugin: nameValuePair "yazi/plugins/${name}.yazi" {source = plugin;}) cfg.plugins)
      // (mapAttrs' (name: flavor: nameValuePair "yazi/flavors/${name}.yazi" {source = flavor;}) cfg.flavors);
  };
}
