{
  inputs,
  pkgs,
  lib,
}: let
  inherit (lib.meta) getExe;
  inherit (inputs.ndg.packages."${pkgs.system}") ndg;

  hjemRumDocs = pkgs.nixosOptionsDoc {
    variablelistId = "hjem-rum-options";
    warningsAreErrors = true;

    options =
      (lib.evalModules {
        modules =
          (lib.filesystem.listFilesRecursive ../modules/collection)
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
                  builtins.mapAttrs (
                    name: value: let
                      wholeName = "${namePrefix}.${name}";
                    in
                      if builtins.isAttrs value
                      then
                        scrubDerivations wholeName value
                        // lib.optionalAttrs (lib.isDerivation value) {
                          inherit (value) drvPath;
                          outPath = "\${${wholeName}}";
                        }
                      else value
                  )
                  pkgSet;
              in {
                _module = {
                  check = false;
                  args.pkgs = lib.mkForce (scrubDerivations "pkgs" pkgs);
                };
              }
            )
          ];
      })
      .options
      .rum;

    transformOptions = opt:
      opt
      // {
        declarations =
          map (
            decl:
              if lib.hasPrefix (toString ../.) (toString decl)
              then
                lib.pipe decl [
                  toString
                  (lib.removePrefix (toString ../.))
                  (lib.removePrefix "/")
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

  optionsJSON =
    pkgs.runCommand "options.json" {
      meta.description = "List of hjem-rum options in JSON format";
    } ''
      mkdir -p $out/{share/doc,nix-support}
      cp -a ${hjemRumDocs.optionsJSON}/share/doc/nixos $out/share/doc/hjem-rum
      substitute \
        ${hjemRumDocs.optionsJSON}/nix-support/hydra-build-products \
        $out/nix-support/hydra-build-products \
        --replace \
        '${hjemRumDocs.optionsJSON}/share/doc/nixos' \
        "$out/share/doc/hjem-rum"
    '';

  html =
    pkgs.runCommand "hjem-rum-html-docs" {}
    ''
      mkdir $out
      ${getExe ndg} -i ${./content} -j ${optionsJSON}/share/doc/hjem-rum/options.json -o $out
    '';
in
  html
