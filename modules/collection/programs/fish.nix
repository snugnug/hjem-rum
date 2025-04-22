{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.strings) typeOf concatMapAttrsStringSep concatMapStringsSep splitString;
  inherit (lib.modules) mkIf;
  inherit (lib.types) either str path oneOf attrsOf nullOr;
  inherit (lib.attrsets) mapAttrs' nameValuePair isDerivation;

  cfg = config.rum.programs.fish;
  env = config.environment.sessionVariables;

  toFish = strOrPath: fileName:
    if (typeOf strOrPath) == "string"
    then pkgs.writers.writeFish fileName strOrPath
    else if isDerivation strOrPath
    then strOrPath
    else throw "Input is of invalid type ${typeOf strOrPath}, expected `path` or `string`.";

  toFishFunc = strOrPath: funcName:
    toFish (
      if (typeOf strOrPath) == "string"
      then ''
        function ${funcName};
        ${concatMapStringsSep "\n" (line: "\t${line}") (splitString "\n" strOrPath)}
        end
      ''
      else strOrPath
    ) "${funcName}.fish";
in {
  options.rum.programs.fish = {
    enable = mkEnableOption "fish";

    package = mkPackageOption pkgs "fish" {};

    config = mkOption {
      default = null;
      type = nullOr (either str path);
      description = ''
        The main configuration for fish, written verbatim to `.config/fish/config.fish`.
      '';
    };

    prompt = mkOption {
      default = null;
      type = nullOr (either str path);
      description = ''
        Your fish prompt, written to `.config/fish/functions/fish_prompt.fish`.
        It follows the behaviour of `rum.programs.fish.functions`.
      '';
    };

    functions = mkOption {
      default = {};
      type = attrsOf (oneOf [str path]);
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
      example = lib.literalExample ''
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
      type = attrsOf (oneOf [str path]);
      description = ''
        Extra configuration files, they will all be written verbatim
        to `.config/fish/conf.d/<name>.fish`.

        Those files are run before `.config/fish/config.fish` as per the fish
        [documentation](https://fishshell.com/docs/current/language.html#configuration-files).
      '';
      example = {
        my-aliases = ''
          alias la "ls -la"
          alias ll "ls -l"
        '';
      };
    };

    abbrs = mkOption {
      default = {};
      type = attrsOf str;
      description = ''
        A set of fish abbreviations, they will be set up with the `abbr --add` fish builtin.
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];

    rum.programs.fish = {
      functions.fish_prompt = mkIf (cfg.prompt != null) cfg.prompt;
      earlyConfigFiles = {
        rum-environment-variables = mkIf (env != {}) ''
          ${concatMapAttrsStringSep "\n" (name: value: "set --global --export ${name} ${toString value}") env}
        '';
        rum-abbreviations = mkIf (cfg.abbrs != {}) ''
          ${concatMapAttrsStringSep "\n" (name: value: "abbr --add -- ${name} ${toString value}") cfg.abbrs}
        '';
      };
    };

    files =
      {".config/fish/config.fish".source = mkIf (cfg.config != null) (toFish cfg.config "config.fish");}
      // (mapAttrs' (name: val: nameValuePair ".config/fish/functions/${name}.fish" {source = toFishFunc val name;}) cfg.functions)
      // (mapAttrs' (name: val: nameValuePair ".config/fish/conf.d/${name}.fish" {source = toFish val "${name}.fish";}) cfg.earlyConfigFiles);
  };
}
