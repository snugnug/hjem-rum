{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) literalExpression mkOption mkEnableOption mkPackageOption;
  inherit (lib.strings) typeOf concatMapAttrsStringSep concatMapStringsSep splitString escapeShellArg;
  inherit (lib.modules) mkIf;
  inherit (lib.types) lines path oneOf attrsOf;
  inherit (lib.attrsets) mapAttrs' nameValuePair isDerivation filterAttrs attrValues;
  inherit (lib.lists) any filter optionals;
  inherit (lib.trivial) pathExists;
  inherit (pkgs.writers) writeFish;

  toFishFunc = body: funcName:
    if (typeOf body) == "string"
    then
      writeFish "${funcName}.fish" ''
        function ${funcName};
        ${concatMapStringsSep "\n" (line: "\t${line}") (splitString "\n" body)}
        end
      ''
    else if isDerivation body
    then body
    else throw "Input is of invalid type ${typeOf body}, expected `path` or `string`.";

  isVendored = plugin:
    any (p: pathExists "${plugin}/share/fish/${p}") [
      "vendor_conf.d"
      "vendor_completions.d"
      "vendor_functions.d"
    ];

  cfg = config.rum.programs.fish;
  env = config.environment.sessionVariables;
in {
  options.rum.programs.fish = {
    enable = mkEnableOption "fish";

    package = mkPackageOption pkgs "fish" {nullable = true;};

    config = mkOption {
      default = "";
      type = lines;
      description = ''
        The main configuration for fish, written verbatim to `.config/fish/config.fish`.
      '';
    };

    functions = mkOption {
      default = {};
      type = attrsOf (oneOf [lines path]);
      description = ''
        A fish function which is being written to `.config/fish/functions/<name>.fish`.

        If the input value is a string, its contents will be wrapped
        inside of a function declaration, like so:
        ```fish
        function <name>;
            <function body>
        end
        ```
        Otherwise you are expected to handle that yourself.
      '';
      example = literalExpression ''
        {
          fish_prompt = pkgs.writers.writeFish "fish_prompt.fish" '\'
              function fish_prompt -d "Write out the prompt"
                    # This shows up as USER@HOST /home/user/ >, with the directory colored
                    # $USER and $hostname are set by fish, so you can just use them
                    # instead of using `whoami` and `hostname`
                    printf '%s@%s %s%s%s > ' $USER $hostname \
                        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
              end
          '\';
          hello-world = '\'
              echo Hello, World!
          '\';
        }'';
    };

    earlyConfigFiles = mkOption {
      default = {};
      type = attrsOf lines;
      description = ''
        Extra configuration files, they will all be written verbatim
        to {file}`$XDG_CONFIG_HOME/fish/conf.d/<name>.fish`.

        Those files are run before {file}`$XDG_CONFIG_HOME/fish/config.fish` as per the [fish documentation].

        [fish documentation]: https://fishshell.com/docs/current/language.html#configuration-files
      '';
      example = {
        set-path = "fish_add_path ~/.local/bin";
      };
    };

    abbrs = mkOption {
      default = {};
      type = attrsOf lines;
      description = ''
        A set of fish abbreviations, they will be set up with the `abbr --add` fish builtin.
      '';
    };

    aliases = mkOption {
      default = {};
      type = attrsOf lines;
      description = ''
        A set of fish aliases, they will be set up with the `alias` fish builtin.
      '';
    };

    plugins = mkOption {
      type = attrsOf path;
      default = {};
      description = ''
        An attrset of plugins.

        In the case where a plugin is a 'vendored' plugin, all we are doing is adding that
        plugin to `hjem.users.<name>.packages`. As fish automatically discovers those files.

        A vendored plugin is denoted by the existence of one of the following files in its derivation:
        - /share/fish/vendor_conf.d
        - /share/fish/vendor_completions.d
        - /share/fish/vendor_functions.d

        This will be the case with plugins present in `pkgs.fishPlugins`.

        For the remaining cases, a file will be created at `~/.config/fish/conf.d/rum-plugin-<name>.fish`.
        It will attempt to handle or source a variety of expected files from the derivation. Those files are:

        - `/functions`: is added to `fish_function_path`
        - `/completions`: is added to `fish_complete_path`
        - `/conf.d/*`, `/key_bindings.fish`, `/init.fish`: sourced in this order

        If a plugin seems to not work, verify that it contains one of the aformentioned files.
      '';
      example = literalExpression ''
        {
          inherit (pkgs.fishPlugins) z;
          pisces = pkgs.fetchFromGitHub {
            owner = "laughedelic";
            repo = "pisces";
            tag = "v0.7.0";
            hash = "sha256-Oou2IeNNAqR00ZT3bss/DbhrJjGeMsn9dBBYhgdafBw=";
          };
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    packages =
      (optionals (cfg.package != null) [cfg.package])
      ++ (filter (pl: isVendored pl) (attrValues cfg.plugins));

    rum.programs.fish.earlyConfigFiles = mapAttrs' (name: source:
      nameValuePair "rum-plugin-${name}"
      #  fish
      ''
        # Plugin ${name} -- ${source}
        set -l src "${source}"

        if test -d "$src/functions"
            set fish_function_path $fish_function_path[1] "$src/functions" $fish_function_path[2..]
        end

        if test -d "$src/completions"
            set fish_complete_path $fish_complete_path[1] "$src/completions" $fish_complete_path[2..]
        end

        for f in "$src/conf.d/"*
            source "$f"
        end

        if test -f "$src/key_bindings.fish"
            source "$src/key_bindings.fish"
        end

        if test -f "$src/init.fish"
            source "$src/init.fish"
        end
      '')
    (filterAttrs (n: v: !(isVendored v)) cfg.plugins);

    xdg.config.files =
      {
        "fish/config.fish".source = mkIf (cfg.config != "") (writeFish "config.fish" cfg.config);
        "fish/conf.d/rum-environment-variables.fish".text = mkIf (env != {}) ''
          ${concatMapAttrsStringSep "\n" (name: value: "set --global --export ${name} ${toString value}") env}
        '';
        "fish/conf.d/rum-abbreviations.fish".text = mkIf (cfg.abbrs != {}) ''
          ${concatMapAttrsStringSep "\n" (name: value: "abbr --add -- ${name} ${escapeShellArg (toString value)}") cfg.abbrs}
        '';
        "fish/conf.d/rum-aliases.fish".text = mkIf (cfg.aliases != {}) ''
          ${concatMapAttrsStringSep "\n" (name: value: "alias -- ${name} ${escapeShellArg (toString value)}") cfg.aliases}
        '';
      }
      // (mapAttrs' (name: val: nameValuePair "fish/functions/${name}.fish" {source = toFishFunc val name;}) cfg.functions)
      // (mapAttrs' (name: val: nameValuePair "fish/conf.d/${name}.fish" {source = writeFish "${name}.fish" val;}) cfg.earlyConfigFiles);
  };
}
