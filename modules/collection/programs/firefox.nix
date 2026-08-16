{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (builtins) attrValues convertHash hashString substring;
  inherit (lib.attrsets) filterAttrs mapAttrs' mapAttrsToList nameValuePair optionalAttrs;
  inherit (lib.generators) toINI;
  inherit (lib.lists) allUnique;
  inherit (lib.modules) mkIf;
  inherit (lib.options) literalExpression mkEnableOption mkOption mkPackageOption showOption;
  inherit (lib.strings) hasPrefix optionalString removePrefix;
  inherit (lib.types) attrsOf bool coercedTo ints nullOr package str submodule;

  json = pkgs.formats.json {};

  outerConfig = config;
  cfg = config.rum.programs.firefox;

  mozlz4 = value: pkgs.runCommand "search.json.mozlz4" {nativeBuildInputs = [pkgs.mozlz4a];} "mozlz4a ${json.generate "search.json" value} $out";

  mkSearchSettings = profile: let
    # https://github.com/mozilla-firefox/firefox/blob/FIREFOX_RELEASE_80_BASE/toolkit/components/search/SearchUtils.jsm#L275-L303
    searchDisclaimer =
      "By modifying this file, I agree that I am doing so only within Firefox "
      + "itself, using official, user-driven search engine selection "
      + "processes, and in a way which does not circumvent user consent. I "
      + "acknowledge that any attempt to change this file from outside of "
      + "Firefox is a malicious act, and will be responded to accordingly.";
    mkDefaultEngineHash = engine:
      convertHash {
        hash = hashString "sha256" (baseNameOf (toString profile.path) + engine + searchDisclaimer);
        hashAlgo = "sha256";
        toHashFormat = "base64";
      };
  in {
    # https://github.com/mozilla-firefox/firefox/blob/FIREFOX_RELEASE_154_BASE/toolkit/components/search/SearchUtils.sys.mjs#L341-L350
    version = 14;
    metaData = let
      inherit (profile.search) default;
    in
      optionalAttrs (default.regular != null) {
        defaultEngineId = default.regular;
        defaultEngineIdHash = mkDefaultEngineHash default.regular;
      }
      // optionalAttrs (default.private != null) {
        privateDefaultEngineId = default.private;
        privateDefaultEngineIdHash = mkDefaultEngineHash default.private;
      };
  };
in {
  options.rum.programs.firefox = {
    enable = mkEnableOption "firefox";

    package = mkPackageOption pkgs "firefox" {nullable = true;};

    startWithLastProfile = mkOption {
      type = bool;
      default = true;
      example = false;
      description = ''
        Whether Firefox should automatically start with the last used
        profile instead of showing the profile manager.
      '';
    };

    profiles = mkOption {
      type = attrsOf (submodule ({
        name,
        config,
        ...
      }: {
        options = {
          id = mkOption {
            type = ints.unsigned;
            default = 0;
            description = ''
              Unique identifier for the profile in
              {file}`$XDG_CONFIG_HOME/mozilla/firefox/profiles.ini`.
            '';
          };

          name = mkOption {
            type = str;
            default = name;
            description = ''
              Name of the profile. If not set, the name of the attribute set
              will be used.
            '';
          };

          path = mkOption {
            type = str;
            default = config.name;
            description = ''
              Path to the profile directory. This may be absolute or relative
              to {file}`$XDG_CONFIG_HOME/mozilla/firefox`.
            '';
          };

          default = mkOption {
            type = bool;
            default = config.id == 0;
            defaultText = literalExpression "profile.id == 0";
            description = ''
              Whether the profile is the default. Defaults to `true` if `id` is
              set to `0`.
            '';
          };

          search = mkOption {
            type = submodule {
              options = {
                default = mkOption {
                  type =
                    coercedTo str (s: {
                      regular = s;
                      private = s;
                    }) (submodule {
                      options = {
                        regular = mkOption {
                          type = nullOr str;
                          default = null;
                          example = "ddg";
                          description = ''
                            The default engine used in regular (non-private)
                            windows.
                          '';
                        };
                        private = mkOption {
                          type = nullOr str;
                          default = null;
                          example = "ddg";
                          description = ''
                            The default engine used in private windows.
                          '';
                        };
                      };
                    });
                  default = {};
                  example = "ddg";
                  description = ''
                    The search engine(s) used by default, referenced by their
                    id. These can be set individually for regular and private
                    windows or for both at the same time with a bare string.
                  '';
                };

                finalConfig = mkOption {
                  type = submodule {
                    options = {
                      target = mkOption {
                        type = str;
                        default =
                          if (hasPrefix "/" config.path)
                          then "${config.path}/search.json.mozlz4"
                          else "${outerConfig.xdg.config.directory}/mozilla/firefox/${config.path}/search.json.mozlz4";
                        defaultText = literalExpression ''
                          if hasPrefix "/" config.path
                          then "''${config.path}/search.json.mozlz4"
                          else "''${config.xdg.config.directory}/mozilla/firefox/''${config.path}/search.json.mozlz4"
                        '';
                        readOnly = true;
                        description = ''
                          Absolute path where this profile's
                          {file}`search.json.mozlz4` should live.
                        '';
                      };
                      source = mkOption {
                        type = package;
                        default = mozlz4 (mkSearchSettings config);
                        readOnly = true;
                        description = ''
                          Derivation containing the compiled
                          {file}`search.json.mozlz4`.
                        '';
                      };
                    };
                  };
                  readOnly = true;
                  description = ''
                    Source and target file paths of the search engine config.

                    In case the profile path is set to an absolute path outside
                    of `$HOME`, the `source` option can be used to link the
                    file at `target` or elsewhere manually by the user.
                  '';
                };
              };
            };
            default = {};
            description = ''
              Search engine configuration written to {file}`search.json.mozlz4`
              in the profile directory.
            '';
          };
        };
      }));
      default = {};
      description = ''
        Profile configurations.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = let
      ids = map (p: p.id) (attrValues cfg.profiles);
    in [
      {
        assertion = allUnique ids;
        message = ''
          Duplicate Firefox profile IDs found in `${showOption ["programs" "firefox" "profiles"]}`.
          Each profile must have a unique `${showOption ["programs" "firefox" "profiles" "<name>" "id"]}`.
        '';
      }
    ];
    warnings = mapAttrsToList (name: profile: ''
      Firefox profile `${name}`: search file target
      `${profile.search.finalConfig.target}` is outside `${config.directory}`;
      hjem-rum will not link it. Use
      `…profiles.\"${name}\".search.finalConfig.source` to link it manually.
    '') (filterAttrs (_: profile: profile.search != {} && !(hasPrefix "${config.directory}/" profile.search.finalConfig.target)) cfg.profiles);

    packages = mkIf (cfg.package != null) [cfg.package];

    files = mapAttrs' (_: profile: nameValuePair (removePrefix "${config.directory}/" profile.search.finalConfig.target) {inherit (profile.search.finalConfig) source;}) (filterAttrs (_: p: hasPrefix "${config.directory}/" p.search.finalConfig.target) cfg.profiles);
    xdg.config.files."mozilla/firefox/profiles.ini" = {
      generator = toINI {};
      value =
        {
          General = {
            StartWithLastProfile =
              if cfg.startWithLastProfile
              then 1
              else 0;
            Version = 2;
          };
        }
        // mapAttrs' (_: profile:
          nameValuePair "Profile${toString profile.id}" {
            Name = profile.name;
            Path = profile.path;
            IsRelative =
              if (substring 0 1 (profile.path) == "/")
              then 0
              else 1;
            Default = optionalString profile.default 1;
          })
        cfg.profiles;
    };
  };
}
