{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption mkPackageOption mkOption literalExpression;
  inherit (lib.modules) mkIf;
  inherit (lib.types) attrsOf anything lines listOf package;
  inherit (lib.strings) concatStringsSep optionalString;
  inherit (lib.attrsets) mapAttrsToList mapAttrs attrValues;
  inherit (lib.lists) flatten;
  inherit (lib.trivial) boolToString;
  inherit (lib.meta) getExe;
  inherit (builtins) isBool isAttrs isList;

  nu.generate = {
    config = settings: let
      nuFormat = attrs:
        mapAttrsToList (
          n: v: let
            v' =
              if isBool v
              then boolToString v
              else if isAttrs v
              then nuFormat attrs.${n}
              else toString v;
          in
            if isList v'
            then
              attrValues (mapAttrs (
                name: list: (map (value: "${name}.${value}") list)
              ) {${n} = v';})
            else "${n} = ${v'}"
        )
        attrs;
    in
      concatStringsSep "\n " (map (v: "$env.config.${v}") (flatten (nuFormat settings)));

    aliases = aliases:
      concatStringsSep "\n " (mapAttrsToList (n: v: "alias ${n} = ${v}") aliases);

    variables = variables: ''
      load-env {${concatStringsSep ", " (mapAttrsToList (n: v: "${n}: \"${v}\"") variables)}}
    '';
  };

  cfg = config.rum.programs.nushell;
in {
  options.rum.programs.nushell = {
    enable = mkEnableOption "nushell";

    package = mkPackageOption pkgs "nushell" {};

    settings = mkOption {
      type = attrsOf anything;
      default = {};
      example = {
        show_banner = false;
        history = {
          file_format = "sqlite";
          max_size = "1_000_000";
          sync_on_enter = true;
          isolation = true;
        };
      };
      description = ''
        A set of options for nushell, flattened, prepended with `$env.config` to avoid overwriting
        (tables of config are overwritten if they occupy the same namespace). It is then written
        to {file}`$XDG_CONFIG_HOME/nushell/config.nu`.

        Please see [The Nushell Book] for configuration options.

        [The Nushell Book]: https://www.nushell.sh/book/configuration.html
      '';
    };

    aliases = mkOption {
      type = attrsOf anything;
      default = {};
      example = {
        ll = "ls -l";
        spp = "spotify_player";
      };
      description = ''
        A set of aliases for nushell, converted into nu and written to
        {file}`$XDG_CONFIG_HOME/nushell/config.nu`. Please note that we cannot
        handle complex aliases that use `def` at this time.

        Please see [The Nushell Book] for a simple tutorial.

        [The Nushell Book]: https://www.nushell.sh/book/aliases.html
      '';
    };

    plugins = mkOption {
      type = listOf package;
      default = [];
      example = literalExpression ''
        with pkgs.nushellPlugins; [
          units
          formats
          query
        ]
      '';
      description = ''
        A list of plugin packages to be installed and added to the
        nushell plugin registry.
      '';
    };

    extraConfig = mkOption {
      type = lines;
      default = "";
      example = ''
        def webdev [--run (-r)] {
          cd ~/my-website
          if $run {
            nix develop --command pnpm run dev
          } else {
            nix develop --command nu
          }
        }
      '';
      description = ''
        Extra configuration to be written to {file}`$XDG_CONFIG_HOME/nushell/config.nu`.

        Please see [The Nushell Book] for more info.

        [The Nushell Book]: https://www.nushell.sh/book/configuration.html
      '';
    };

    envFile = mkOption {
      type = lines;
      default = "";
      description = ''
        [The Nushell Book]: https://www.nushell.sh/book/configuration.html

        Extra configuration to be written to {file}`$XDG_CONFIG_HOME/nushell/env.nu`.
        Please keep in mind that the upstream documentation generally advises against
        writing to this file, and instead suggests using {file}`$XDG_CONFIG_HOME/nushell/config.nu`.

        See [The Nushell Book] for more info.

      '';
    };

    loginFile = mkOption {
      type = lines;
      default = "";
      description = ''
        Nushell may be used as a login shell, so this option writes to
        {file}`$XDG_CONFIG_HOME/nushell/login.nu` to allow you to configure
        nushell as your login shell.

        Please recognize that this is mainly for advanced users and is not
        for the faint of heart. Direct your questions and concerns to
        [The Nushell Book] for more information.

        [The Nushell Book]: https://www.nushell.sh/book/configuration.html#configuring-nu-as-a-login-shell
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = [cfg.package];
    xdg.config.files = let
      checks = {
        settings = cfg.settings != {};
        aliases = cfg.aliases != {};
        extraConfig = cfg.extraConfig != "";
        variables = config.environment.sessionVariables != {};
      };
    in {
      "nushell/config.nu".text = mkIf (checks.settings || checks.aliases || checks.extraConfig || checks.variables) (
        concatStringsSep "\n" [
          (optionalString checks.settings (nu.generate.config cfg.settings))
          (optionalString checks.aliases (nu.generate.aliases cfg.aliases))
          (optionalString checks.variables (nu.generate.variables config.environment.sessionVariables))
          cfg.extraConfig
        ]
      );
      "nushell/env.nu".text = mkIf (cfg.envFile != "") cfg.envFile;

      # from https://github.com/nushell/nushell/discussions/12997#discussioncomment-9638977
      # also used in home manager
      "nushell/plugin.msgpackz".source = mkIf (cfg.plugins != []) (
        let
          msgPackz = pkgs.runCommand "nuPlugin-msgPackz" {} ''
            mkdir -p "$out"
            ${getExe cfg.package} \
              --plugin-config "$out/plugin.msgpackz" \
              --commands '${
              concatStringsSep "\n" (map (plugin: "plugin add ${getExe plugin}") cfg.plugins)
            }'
          '';
        in "${msgPackz}/plugin.msgpackz"
      );
      "nushell/login.nu".text = mkIf (cfg.loginFile != "") cfg.loginFile;
    };
  };
}
