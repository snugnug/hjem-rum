{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types) listOf;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.spotify-player;
in {
  options.rum.programs.spotify-player = {
    enable = mkEnableOption "spotify_player";

    package = mkPackageOption pkgs "spotify-player" {};

    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
        enable_notify = false;
        device = {
          name = "nixos"; # bad hostname, don't do this
          device_type = "computer";
          volume = 40;
          normalization = true;
        };
      };
      description = ''
        The configuration converted into TOML and written to
        `''${config.directory}/.config/spotify-player/app.toml`.

        Please reference https://github.com/aome510/spotify-player/blob/master/docs/config.md#general
        for config options.
      '';
    };

    themes = mkOption {
      type = listOf toml.type;
      default = [];
      example = [
        {
          name = "default2";
          palette = {
            black = "black";
            red = "red";
            green = "green";
            yellow = "yellow";
            blue = "blue";
            magenta = "magenta";
            cyan = "cyan";
            white = "white";
            bright_black = "bright_black";
            bright_red = "bright_red";
            bright_green = "bright_green";
            bright_yellow = "bright_yellow";
            bright_blue = "bright_blue";
            bright_magenta = "bright_magenta";
            bright_cyan = "bright_cyan";
            bright_white = "bright_white";
          };
          component_style = {
            like = {
              fg = "Red";
              modifiers = ["Bold"];
            };
            selection = {
              bg = "Black";
              fg = "White";
              modifiers = ["Bold"];
            };
            secondary_row = {
              bg = "#677075";
            };
          };
        }
      ];
      description = ''
        The theme converted into TOML and written to
        `''${config.directory}/.config/spotify-player/themes.toml`.

        Please reference https://github.com/aome510/spotify-player/blob/master/docs/config.md#themes
        for config options.
      '';
    };

    keymap = mkOption {
      type = toml.type;
      default = {};
      example = {
        keymaps = [
          {
            command = "NextTrack";
            key_sequence = "g n";
          }
        ];
        actions = [
          {
            action = "GoToArtist";
            key_sequence = "g A";
          }
        ];
      };
      description = ''
        Sets of keymaps and actions converted into TOML and written to
        `''${config.directory}/.config/spotify-player/keymap.toml`.
        See example for how to format declarations.

        Please reference https://github.com/aome510/spotify-player/blob/master/docs/config.md#keymaps
        for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files = {
      ".config/spotify-player/app.toml".source = mkIf (cfg.settings != {}) (
        toml.generate "spotify-player/app.toml" cfg.settings
      );

      # Passes each declared theme under the "themes" attr as needed
      ".config/spotify-player/theme.toml".source = mkIf (cfg.themes != []) (
        toml.generate "spotify-player/theme.toml" {inherit (cfg) themes;}
      );

      ".config/spotify-player/keymap.toml".source = mkIf (cfg.keymap != {}) (
        toml.generate "spotify-player/keymap.toml" cfg.keymap
      );
    };
  };
}
