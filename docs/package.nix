{
  ndg,
  pkgs,
  lib,
  rumLib,
}: let
  inherit (builtins) isAttrs toString;
  inherit (lib.attrsets) isDerivation mapAttrs optionalAttrs;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.modules) mkForce evalModules;
  inherit (lib.options) mkOption;
  inherit (lib.strings) hasPrefix removePrefix;
  inherit (lib.trivial) pipe;

  configJSON =
    (pkgs.nixosOptionsDoc {
      variablelistId = "hjem-rum-options";
      warningsAreErrors = true;

      inherit
        (
          (evalModules {
            specialArgs = {inherit rumLib;};
            modules =
              (listFilesRecursive ../modules/collection)
              ++ [
                (
                  let
                    # From nixpkgs:
                    #
                    # Recursively replace each derivation in the given attribute set
                    # with the same derivation but with the `outPath` attribute set to
                    # the string `"\${pkgs.attribute.path}"`. This allows the
                    # documentation to refer to derivations through their values without
                    # establishing an actual dependency on the derivation output.
                    #
                    # This is not perfect, but it seems to cover a vast majority of use cases.
                    #
                    # Caveat: even if the package is reached by a different means, the
                    # path above will be shown and not e.g.
                    # `${config.services.foo.package}`.
                    scrubDerivations = namePrefix: pkgSet:
                      mapAttrs (
                        name: value: let
                          wholeName = "${namePrefix}.${name}";
                        in
                          if isAttrs value
                          then
                            scrubDerivations wholeName value
                            // optionalAttrs (isDerivation value) {
                              inherit (value) drvPath;
                              outPath = "\${${wholeName}}";
                            }
                          else value
                      )
                      pkgSet;
                  in {
                    _module = {
                      check = false;
                      args.pkgs = mkForce (scrubDerivations "pkgs" pkgs);
                    };
                  }
                )
                # avoid having `_module.args` in the documentation
                {
                  options = {
                    _module.args = mkOption {
                      internal = true;
                    };
                  };
                }
              ];
          })
        )
        options
        ;

      transformOptions = opt:
        opt
        // {
          declarations =
            map (
              decl:
                if hasPrefix (toString ../.) (toString decl)
                then
                  pipe decl [
                    toString
                    (removePrefix (toString ../.))
                    (removePrefix "/")
                    (x: {
                      url = "https://github.com/snugnug/hjem-rum/blob/main/${x}";
                      name = "<hjem-rum/${x}>";
                    })
                  ]
                else if decl == "lib/modules.nix"
                then {
                  url = "https://github.com/NixOS/nixpkgs/blob/master/${decl}";
                  name = "<nixpkgs/lib/modules.nix>";
                }
                else decl
            )
            opt.declarations;
        };
    })
    .optionsJSON;

  hjemRumDocs =
    pkgs.runCommandLocal "hjem-rum-docs" {nativeBuildInputs = [ndg];}
    ''
      mkdir -p $out

      ndg \
        --verbose html \
        --title "Hjem Rum"  \
        --jobs $NIX_BUILD_CORES \
        --module-options ${configJSON}/share/doc/nixos/options.json \
        --manpage-urls ${./manpage-urls.json} \
        --options-depth 3 \
        --generate-search true \
        --input-dir ${./.} \
        --output-dir "$out"

      echo rum.snugnug.org > "$out/CNAME"
    '';
in
  hjemRumDocs
