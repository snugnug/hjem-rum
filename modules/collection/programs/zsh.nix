{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (builtins) any attrValues filter;
  inherit (lib.attrsets) mapAttrsToList;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkRenamedOptionModule;
  inherit (lib.options) literalExpression mkEnableOption mkPackageOption mkOption;
  inherit (lib.strings) concatStringsSep optionalString;
  inherit (lib.trivial) id;
  inherit (lib.types) attrsOf bool lines nullOr path submodule str;

  mkPlugins = plugins:
    concatStringsSep "\n"
    (mapAttrsToList (_: value:
      # this is to avoid writing empty strings into .zshrc
        concatStringsSep "\n" (filter (s: s != "") [
          (optionalString (value.src != null) "fpath+=${value.src}")
          ''
            if [[ -f "${value.src}/${value.file}" ]]; then
              source "${value.src}/${value.file}"
            fi
          ''
        ]))
    plugins);

  mkShellConfigOption = configLocation:
    mkOption {
      type = lines;
      default = "";
      description = ''
        Commands that will be added verbatim to ${configLocation}.;
      '';
    };

  cfg = config.rum.programs.zsh;
in {
  imports = [
    (
      mkRenamedOptionModule
      ["rum" "programs" "zsh" "integrations" "starship" "enable"]
      ["rum" "programs" "starship" "integrations" "zsh" "enable"]
    )
  ];
  options.rum.programs.zsh = {
    enable = mkEnableOption "zsh module.";
    package = mkPackageOption pkgs "zsh" {};
    plugins = mkOption {
      type = attrsOf (
        submodule (
          {config, ...}: {
            options = {
              name = mkOption {
                type = str;
                description = ''
                  The name of the plugin.
                '';
              };
              src = mkOption {
                type = nullOr path;
                default = null;
                example = literalExpression ''"''${pkgs.nix-zsh-completions}/share/zsh/plugins/nix"'';
                description = ''
                  Path to the plugin directory.
                  If using a derivation from nixpkgs, this would be the directory in which the main plugin file is stored.

                  This directory will also be added to {env}`fpath` and {env}`PATH`.
                '';
              };
              file = mkOption {
                type = str;
                description = ''
                  The plugin script to source. This is necessary in case the main plugin file does not follow
                  plugin naming conventions, i.e. ``<plugin_name>.plugin.zsh`.
                '';
              };
            };

            # default is here and not above so we can still generate static documentation
            config.file = lib.mkDefault "${config.name}.plugin.zsh";
          }
        )
      );
      default = {};
      description = ''
        Plugins to be loaded in {file}.zshrc.
      '';
    };
    initConfig = mkShellConfigOption "{file}`.zshrc`";
    loginConfig = mkShellConfigOption "{file}`.zlogin`";
    logoutConfig = mkShellConfigOption "{file}`.zlogout`";
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    files = let
      check = {
        environment = config.environment.sessionVariables != {};
        plugins = cfg.plugins != [];
        initConfig = cfg.initConfig != "";
      };
    in {
      ".zshenv".source = mkIf check.environment config.environment.loadEnv;
      ".zshrc".text =
        # this makes it less verbose to check if any boolean in `check` is true
        mkIf (any id (attrValues check))
        (
          optionalString check.plugins (mkPlugins cfg.plugins)
          + optionalString check.initConfig cfg.initConfig
        );
    };
  };
}
