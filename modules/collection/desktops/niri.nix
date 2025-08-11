{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (builtins) mapAttrs concatStringsSep isBool isInt;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption literalExpression mkPackageOption;
  inherit (lib.strings) concatMapStringsSep optionalString;
  inherit (lib.trivial) pipe boolToString;
  inherit (lib.types) listOf path attrsOf anything str lines submodule nullOr;

  toNiriSpawn = commands:
    concatMapStringsSep " " (arg: "\"${arg}\"") commands;

  toNiriBinds = binds:
    concatStringsSep "\n" (mapAttrsToList (
        bind: bindOptions: let
          parameters = pipe bindOptions.parameters [
            (mapAttrs (
              _: value:
                if isBool value
                then boolToString value
                else if isInt value
                then toString value
                else if isNull value
                then "null"
                else ''"${value}"''
            ))
            (mapAttrsToList (name: value: "${name}=${value}"))
            (concatStringsSep " ")
          ];
          action = let
            spawnIsNull = isNull bindOptions.spawn;
            actionIsNull = isNull bindOptions.action;
          in
            if spawnIsNull && actionIsNull
            then throw "${bind} is missing an action or spawn to perform."
            else if !spawnIsNull && !actionIsNull
            then throw "${bind} cannot be assigned both an action and a spawn. Only one may be set."
            else if spawnIsNull
            then bindOptions.action
            else "spawn " + toNiriSpawn bindOptions.spawn;
        in "${bind} ${parameters} {${action};}"
      )
      binds);

  toNiriSpawnAtStartup = spawn:
    concatMapStringsSep "\n" (
      commands:
        "spawn-at-startup " + (toNiriSpawn commands)
    )
    spawn;

  niriEnvironment = pipe (config.environment.sessionVariables // cfg.extraVariables) [
    (mapAttrsToList (n: v: n + " \"${v}\""))
    (concatStringsSep "\n")
  ];

  bindsModule = submodule {
    options = {
      spawn = mkOption {
        type = nullOr (listOf str);
        default = null;
        example = ["foot" "-e" "fish"];
        description = ''
          [niri's wiki]: https://github.com/YaLTeR/niri/wiki/Configuration:-Key-Bindings

          The spawn action to run on button-press. For other actions, please see
          {option}`binds.<keybind>.actions`. See [niri's wiki] for more information.
        '';
      };
      action = mkOption {
        type = nullOr str;
        default = null;
        example = "focus-column-left";
        description = ''
          [niri's wiki]: https://github.com/YaLTeR/niri/wiki/Configuration:-Key-Bindings

          The non-spawn action to run on button-press. For spawning processes, please see
          {option}`binds.<keybind>.spawn`. See [niri's wiki] for a complete list.
        '';
      };
      parameters = mkOption {
        type = attrsOf anything;
        default = {};
        example = {
          allow-when-locked = true;
          cooldown-ms = 150;
        };
        description = ''
          [niri's wiki]: https://github.com/YaLTeR/niri/wiki/Configuration:-Key-Bindings

          The parameters to append to the bind. See [niri's wiki] for a complete list.
        '';
      };
    };
  };

  cfg = config.rum.desktops.niri;
in {
  options.rum.desktops.niri = {
    enable = mkEnableOption "niri: A scrollable-tiling Wayland compositor";
    package = mkPackageOption pkgs "niri" {
      nullable = true;
      extraDescription = ''
        Only used to validate the generated config file. Set to `null` to
        disable the check phase.
      '';
    };
    binds = mkOption {
      type = attrsOf bindsModule;
      default = {};
      example = {
        "Mod+Return" = {
          spawn = ["foot" "-e" "fish"];
          parameters = {
            allow-when-locked = true;
            cooldown-ms = 150;
          };
        };
        "Mod+D" = {
          action = "close-window";
          parameters = {
            repeat = false;
          };
        };
      };
      description = ''
        [niri's wiki]: https://github.com/YaLTeR/niri/wiki/Configuration:-Key-Bindings

        A list of key bindings that will be added to the configuration file. See [niri's wiki] for a complete list.
      '';
    };
    spawn-at-startup = mkOption {
      type = listOf (listOf str);
      default = [];
      example = literalExpression ''
        [
          ["waybar"]
          ["${getExe pkgs.alacritty}" "-e" "fish"]
        ]
      '';
      description = ''
        [niri's wiki]: https://github.com/YaLTeR/niri/wiki/Configuration:-Miscellaneous

        A list of programs to be loaded with niri on startup. see [niri's wiki] for more details on the API.
      '';
    };
    extraVariables = mkOption {
      type = attrsOf str;
      default = {};
      example = {
        DISPLAY = ":0";
      };
      description = ''
        Extra environmental variables to be added to Niri's `enviroment` node.
        This can be used to override variables set in {option}`enviroment.sessionVariables`.
        You can therefore set a variable to `null` to force unset it in Niri.
      '';
    };
    configFile = mkOption {
      type = path;
      default = [];
      example = "./config.kdl";
      description = ''
        [niri's wiki]: https://github.com/YaLTeR/niri/wiki/Configuration:-Introduction

        Concat with generated files and symlinked to {file}`$HOME/niri/config.kdl`. See a full
        list of options in [niri's wiki].
        To add to environment, please use {option}`environment.sessionVariables`.

        You can also modularize your config by using `pkgs.concatText`:

        ```nix
          configFile = pkgs.concatText "full-config.kdl" [
            input.kdl
            rules.kdl
          ];
        ```

        You could even optionally import certain files using something like this:

        ```nix
          # lib.flatten takes the elements of lists inside a list and moves them into one list
          configFiles = pkgs.concatText "full-config.kdl" (lib.flatten [
            ./config.kdl
            (lib.optional (config.powersave.enable) ./laptop-config.kdl)
            (lib.optional (config.programs.firefox.enable) ./firefox-rules.kdl
          ]);
          ;
        ```

        Be warned, however, that some KDL nodes (such as `binds`) cannot have duplicates. However, this
        should work great for `window-rule`s, `output`s, and other such situations.
      '';
    };
    extraConfig = mkOption {
      type = lines;
      default = "";
      example = literalExpression ''
        screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

        switch-events {
          tablet-mode-on { spawn "${getExe pkgs.bash}" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"; }
          tablet-mode-off { spawn "${getExe pkgs.bash}" "-c" "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled false"; }
        }
      '';
      description = ''
        [niri's wiki]: https://github.com/YaLTeR/niri/wiki/Configuration:-Introduction

        Lines of KDL code that are added to {file}`$HOME/.config/niri/config.kdl`.
        See a full list of options in [niri's wiki].
        To add to environment, please use {option}`environment.sessionVariables`.
      '';
    };
  };

  config = mkIf cfg.enable {
    files.".config/niri/config.kdl".source = pkgs.concatTextFile {
      name = "niri-config.kdl";
      files = [
        cfg.configFile
        (pkgs.writeText "generated-niri-config" (
          concatStringsSep "\n" [
            ''
              environment {
                ${niriEnvironment}
              }
              binds {
                ${toNiriBinds cfg.binds}
              }
            ''
            (toNiriSpawnAtStartup cfg.spawn-at-startup)
            cfg.extraConfig
          ]
        ))
      ];
      checkPhase = optionalString (cfg.package != null) ''
        ${getExe cfg.package} validate -c "$file"
      '';
    };
  };
}
