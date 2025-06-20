{
  lib,
  config,
  rumLib,
  ...
}: let
  inherit (lib.options) literalExpression mkOption mkEnableOption;
  inherit (lib.types) listOf package lines str;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optionals;
  inherit (lib.attrsets) optionalAttrs;
  inherit (rumLib.generators.gtk) toGtk2Text toGtkINI;
  inherit (rumLib.types) gtkType;
  inherit (rumLib.attrsets) attrNamesHasPrefix;
  inherit (builtins) hasAttr concatStringsSep;

  cfg = config.rum.misc.gtk;
in {
  options.rum.misc.gtk = {
    enable = mkEnableOption "GTK configuration";
    packages = mkOption {
      type = listOf package;
      default = [];
      example = literalExpression ''
        [
          (pkgs.catppuccin-papirus-folders.override {
            accent = "rosewater";
            flavor = "mocha";
          })
          pkgs.bibata-cursors
        ];
      '';
      description = ''
        The list of packages to be installed for gtk themes.
        This list should consist of any packages that will be used
        by your GTK theme(s).
      '';
    };
    settings = mkOption {
      type = gtkType;
      default = {};
      example = {
        theme-name = "Arc-Dark";
        font-name = "Sans 11";
        application-prefer-dark-theme = true;
      };
      description = ''
        The settings that will be written to the various gtk files
        to configure the GTK theme. GTK documentation is perhaps
        nebulous, but the [Arch Wiki entry] and the [official GTK
        documentation] are decent places to start.

        Please note that each option name will have "gtk-" prepended
        to it, so there is no need to include that on every single option.

        [Arch Wiki entry]: https://wiki.archlinux.org/title/GTK
        [official GTK documentation]: https://docs.gtk.org/gtk3/class.Settings.html
      '';
    };
    css = {
      gtk3 = mkOption {
        type = lines;
        default = "";
        description = ''
          CSS to be written to {file}`$HOME/.config/gtk-3.0/gtk.css`.
          You can either use this as lines or you can reference
          a CSS file from your theme's package (or both).
        '';
      };
      gtk4 = mkOption {
        type = lines;
        default = "";
        description = ''
          CSS to be written to {file}`$HOME/.config/gtk-4.0/gtk.css`.
          You can either use this as lines or you can reference
          a CSS file from your theme's package (or both).
        '';
      };
    };
    bookmarks = mkOption {
      type = listOf str;
      default = [];
      example = [
        "file:///home/user/Documents Documents"
        "file:///home/user/Music Music"
        "file:///home/user/Pictures Pictures"
        "file:///home/user/Videos Videos"
        "file:///home/user/Downloads Downloads"
      ];
      description = ''
        Bookmarks used by GTK file managers (ex. Nautilus).
        Each entry should have one of the following formats:
        - `[uri]`
        - `[uri] <display name>`
      '';
    };
  };
  config = mkIf cfg.enable {
    # We could also just automatically fix it, but for now, simply
    # check if the user accidentally included a 'gtk-' prefix.
    warnings = optionals (attrNamesHasPrefix "gtk-" cfg.settings) [
      "Each option in 'rum.misc.gtk.settings' is automatically prefixed with 'gtk-' if it is not present already. You have added this to an option unnecessarily."
    ];

    inherit (cfg) packages;

    files = (
      optionalAttrs (cfg.settings != {}) {
        ".gtkrc-2.0".text = toGtk2Text {inherit (cfg) settings;};
        ".config/gtk-3.0/settings.ini".text = toGtkINI {Settings = cfg.settings;};
        ".config/gtk-4.0/settings.ini".text = toGtkINI {Settings = cfg.settings;};
      }
      // optionalAttrs (cfg.css.gtk3 != "") {
        ".config/gtk-3.0/gtk.css".text = cfg.css.gtk3;
      }
      // optionalAttrs (cfg.css.gtk4 != "") {
        ".config/gtk-4.0/gtk.css".text = cfg.css.gtk4;
      }
      // optionalAttrs (cfg.bookmarks != []) {
        ".config/gtk-3.0/bookmarks".text = concatStringsSep "\n" cfg.bookmarks;
      }
    );

    # Set sessionVariables to load
    environment.sessionVariables = {
      GTK2_RC_FILES = "${config.directory}/.gtkrc-2.0";
      GTK_THEME = mkIf (hasAttr "theme-name" cfg.settings) cfg.settings.theme-name;
    };
  };
}
