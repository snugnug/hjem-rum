{
  config,
  hjem-lib,
  lib,
  pkgs,
  rumLib,
  ...
}: let
  inherit (hjem-lib) envVarType;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExpression mkEnableOption mkOption mkPackageOption;
  inherit (lib.strings) hasPrefix;
  inherit (rumLib.attrsets) attrNamesHasPrefix;

  cfg = config.rum.programs.password-store;

  prefixedEnvironment =
    mapAttrs' (
      name: value:
        nameValuePair
        (
          if hasPrefix "PASSWORD_STORE_" name
          then name
          else "PASSWORD_STORE_${name}"
        )
        value
    )
    cfg.environment;
in {
  options.rum.programs.password-store = {
    enable = mkEnableOption "password-store";

    package = mkPackageOption pkgs "pass" {
      nullable = true;
      extraDescription = ''
        To get extensions to work, you will need to wrap the pass derivation
        with the extensions you want. Consult the [pass extensions directory]
        for a list of available extensions.

        [pass extensions directory]: https://github.com/NixOS/nixpkgs/tree/master/pkgs/tools/security/pass/extensions
      '';
      example = ''
        pkgs.pass.withExtensions (exts: [
          exts.pass-otp
          exts.pass-import
        ])
      '';
    };

    environment = mkOption {
      type = envVarType;
      default = {};
      example = literalExpression ''
        {
          DIR = "''${config.xdg.data.directory}/password-store";
          CLIP_TIME = 60;
        }
      '';
      description = ''
        The configuration added to `environment.sessionVariables`, as
        password-store is configured entirely through environment variables.
        Please reference {manpage}`pass(1)` for configuration options.

        Please note that each option name will have "PASSWORD_STORE_"
        prepended to it, so there is no need to include that on every single
        option. Variables outside of that namespace, such as {env}`EDITOR`,
        should be set through {option}`environment.sessionVariables` instead.

        These variables are only loaded by modules such as
        {option}`rum.programs.fish.enable`. See [environmental variables] for
        more information.

        [environmental variables]: https://github.com/snugnug/hjem-rum#environmental-variables
      '';
    };
  };

  config = mkIf cfg.enable {
    # The prefix is added for the user, so simply check if they accidentally included it themselves.
    warnings = optionals (attrNamesHasPrefix "PASSWORD_STORE_" cfg.environment) [
      "Each option in 'rum.programs.password-store.environment' is automatically prefixed with 'PASSWORD_STORE_' if it is not present already. You have added this to an option unnecessarily."
    ];

    packages = mkIf (cfg.package != null) [cfg.package];
    environment.sessionVariables = prefixedEnvironment;
  };
}
