{
  inputs,
  pkgs,
  lib,
  rumLib,
}: let
  inherit (builtins) isAttrs mapAttrs toString;
  inherit (lib.attrsets) filterAttrs isDerivation optionalAttrs;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.meta) getExe;
  inherit (lib.modules) evalModules mkForce;
  inherit (lib.strings) hasPrefix removePrefix;
  inherit (lib.trivial) pipe;

  inherit (inputs.ndg.packages."${pkgs.system}") ndg;

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
                # This is not perfect, but it seems to cover a vast majority of use
                # cases.
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
          ];
      })
    )
    options
    ;

  filteredOptions = filterAttrs (n: _: n != "_module") options;

  hjemRumDocs = pkgs.nixosOptionsDoc {
    warningsAreErrors = true;

    options = filteredOptions;

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
  };

  html = pkgs.runCommandLocal "hjem-rum-docs" {} ''
    mkdir -p $out
    ${getExe ndg} options \
    --input-dir ${./manual} \
    --module-options ${hjemRumDocs.optionsJSON}/share/doc/nixos/options.json \
    --manpage-urls ${./manpage-urls.json} \
    --options-depth 3 \
    --revision "https://github.com/snugnug/hjem-rum/tree/main" \
    --jobs $NIX_BUILD_CORES \
    --generate-search true \
    --title "Hjem Rum" \
    --output-dir $out
  '';
in
  html
