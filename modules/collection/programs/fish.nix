{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.strings) typeOf concatMapAttrsStringSep concatMapStringsSep splitString;
  inherit (lib.modules) mkIf;
  inherit (lib.types) either str path oneOf attrsOf nullOr bool;
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

    exportEnvVars = mkOption {
      default = true;
      type = bool;
      description = ''
        Wether to export environment variables set in ''${config.environment.systemVariables}.
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
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];

    rum.programs.fish.functions.fish_prompt = mkIf (cfg.prompt != null) cfg.prompt;

    files =
      {
        ".config/fish/config.fish".source = mkIf (cfg.config != null) (toFish cfg.config "config.fish");

        ".config/fish/conf.d/environment-variables.fish".text = mkIf (env != {} && cfg.exportEnvVars) ''
          ${concatMapAttrsStringSep "\n" (name: value: "set -gx ${name} ${toString value}") env}
        '';
      }
      // (mapAttrs' (name: val: nameValuePair ".config/fish/functions/${name}.fish" {source = toFishFunc val name;}) cfg.functions);
  };
}
