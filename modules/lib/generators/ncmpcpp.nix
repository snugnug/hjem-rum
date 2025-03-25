{lib}: let
  inherit (builtins) toString typeOf map concatStringsSep;
  inherit (lib.attrsets) mapAttrsToList;
in {
  toNcmpcppBinding = settings: let
    genSubmodule = suffix: submodule:
      concatStringsSep "\n" (map (
          attrset: ''
            def_${suffix} "${attrset.binding}" [${
              if attrset.deferred == true
              then "deferred"
              else "immediate"
            }]
              ${concatStringsSep "\n  " attrset.actions}
          ''
        )
        submodule);
  in ''
    ${
      if (settings ? keys)
      then (genSubmodule "key" settings.keys)
      else ""
    }
    ${
      if (settings ? commands)
      then (genSubmodule "command" settings.commands)
      else ""
    }
  '';

  toNcmpcppSettings = settings: let
    convertValue = value:
      {
        string = value;
        int = toString value;
        path = toString value;
        bool =
          if value
          then "yes"
          else "no";
      }
      .${typeOf value};
  in
    concatStringsSep "\n" (mapAttrsToList (name: value: "${name} = ${convertValue value}") settings);
}
