{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) nameValuePair;
  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExample mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) attrsOf;

  json = pkgs.formats.json {};

  cfg = config.rum.programs.zed;
in {
  options.rum.programs.zed = {
    enable = mkEnableOption "zed";

    package = mkPackageOption pkgs "zed-editor" {};

    settings = mkOption {
      type = json.type;
      default = {};
      example = {
        autosave = "on_focus_change";
        base_keymap = "Atom";
        buffer_font_fallbacks = ["Nerd Font"];
        load_direnv = "shell_hook";
        theme = {
          mode = "system";
          light = "One Light";
          dark = "One Dark";
        };
      };
      description = ''
        Configuration written to {file}`$HOME/.config/zed/settings.json`.
        Please reference [zed's documentation] for config options.

        [zed's documentation]: https://zed.dev/docs/configuring-zed
      '';
    };

    keymap = mkOption {
      type = json.type;
      default = {};
      example = [
        {
          "bindings" = {
            "ctrl-right" = "editor::SelectLargerSyntaxNode";
            "ctrl-left" = "editor::SelectSmallerSyntaxNode";
          };
        }
        {
          "context" = "ProjectPanel && not_editing";
          "bindings" = {
            "o" = "project_panel::Open";
          };
        }
      ];
      description = ''
        Configuration written to {file}`$HOME/.config/zed/keymap.json`.
        Please reference [zed's documentation] for config options.

        [zed's documentation]: https://zed.dev/docs/key-bindings
      '';
    };

    snippets = mkOption {
      type = attrsOf json.type;
      default = {};
      example = literalExample ''
        {
          snippets = {
            # Each snippet must have a name and body, but the prefix and description are optional.
            # The prefix is used to trigger the snippet, but when omitted then the name is used.
            # Use placeholders like $1, $2 or ''${1:defaultValue} to define tab stops.
            # The $0 determines the final cursor position.
            # Placeholders with the same value are linked.
            "Log to console" = {
              prefix = "log";
              body = ["console.info(\"Hello, ''\${1:World}!\")" "$0"];
              description = "Logs to console";
            };
          };
        }
      '';
      description = ''
        Custom scoped snippets written to {file}`$HOME/.config/zed/snippets/*.json`
        Please reference [zed's documentation] for more details.

        [zed's documentation]: https://zed.dev/docs/snippets
      '';
    };

    themes = mkOption {
      type = attrsOf json.type;
      default = {};
      description = ''
        Custom themes written to {file}`$HOME/.config/zed/themes/*.json`
        Please reference [zed's documentation] for more details.

        [zed's documentation]: https://zed.dev/docs/extensions/themes
      '';
    };

    tasks = mkOption {
      type = json.type;
      default = {};
      example = [
        {
          "label" = "Example task";
          "command" = "for i in {1..5}; do echo \"Hello $i/5\"; sleep 1; done";
          "env" = {"foo" = "bar";};
          "use_new_terminal" = false;
          "allow_concurrent_runs" = false;
          "reveal" = "always";
          "hide" = "never";
          "shell" = "system";
          "show_summary" = true;
          "show_output" = true;
          "tags" = [];
        }
      ];
      description = ''
        Configuration written to {file}`$HOME/.config/zed/tasks.json`.
        Please reference [zed's documentation] for config options.

        [zed's documentation]: https://zed.dev/docs/tasks
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files =
      {
        ".config/zed/settings.json".source = mkIf (cfg.settings != {}) (
          json.generate "zed-settings.json" cfg.settings
        );
        ".config/zed/keymap.json".source = mkIf (cfg.keymap != {}) (
          json.generate "zed-keymap.json" cfg.keymap
        );
        ".config/zed/tasks.json".source = mkIf (cfg.tasks != {}) (
          json.generate "zed-tasks.json" cfg.tasks
        );
      }
      // (lib.mapAttrs' (name: value:
        nameValuePair ".config/zed/snippets/${name}.json" {
          source = json.generate "zed-${name}-snippet.json" value;
        })
      cfg.snippets)
      // (lib.mapAttrs' (name: value:
        nameValuePair ".config/zed/themes/${name}.json" {
          source = json.generate "zed-${name}-theme.json" value;
        })
      cfg.themes);
  };
}
