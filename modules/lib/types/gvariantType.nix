# taken from https://github.com/nix-community/home-manager/blob/fcac3d6d88302a5e64f6cb8014ac785e08874c8d/modules/lib/gvariant.nix
# A partial and basic implementation of GVariant formatted strings.
#
# Note, this API is not considered fully stable and it might therefore
# change in backwards incompatible ways without prior notice.
{lib}: let
  inherit (builtins) all head;
  inherit (lib) throw;
  inherit (lib.gvariant) isGVariant mkValue;
  inherit (lib.lists) foldl';
  inherit (lib.options) getFiles mergeDefaultOption mergeOneOption showFiles showOption;
  inherit (lib.strings) hasPrefix;
  inherit (lib.types) float listOf str;

  type = {
    string = "s";
    boolean = "b";
    uchar = "y";
    int16 = "n";
    uint16 = "q";
    int32 = "i";
    uint32 = "u";
    int64 = "x";
    uint64 = "t";
    double = "d";
    variant = "v";
  };

  isArray = hasPrefix "a";
  isDictionaryEntry = hasPrefix "{";
  isMaybe = hasPrefix "m";
  isTuple = hasPrefix "(";

  gvariant = lib.mkOptionType rec {
    name = "gvariant";
    description = "GVariant value";
    check = v: mkValue v != null;
    merge = loc: defs: let
      vdefs = map (d:
        d
        // {
          value =
            if isGVariant d.value
            then d.value
            else mkValue d.value;
        })
      defs;
      vals = map (d: d.value) vdefs;
      defTypes = map (x: x.type) vals;
      sameOrNull = x: y:
        if x == y
        then y
        else null;
      # A bit naive to just check the first entry…
      sharedDefType = foldl' sameOrNull (head defTypes) defTypes;
      allChecked = all (x: check x) vals;
    in
      if sharedDefType == null
      then
        throw ("Cannot merge definitions of `${showOption loc}' with"
          + " mismatched GVariant types given in"
          + " ${showFiles (getFiles defs)}.")
      else if isArray sharedDefType && allChecked
      then
        mkValue ((listOf gvariant).merge loc
          (map (d: d // {value = d.value.value;}) vdefs))
        // {
          type = sharedDefType;
        }
      else if isTuple sharedDefType && allChecked
      then mergeOneOption loc defs
      else if isMaybe sharedDefType && allChecked
      then mergeOneOption loc defs
      else if isDictionaryEntry sharedDefType && allChecked
      then mergeOneOption loc defs
      else if type.variant == sharedDefType && allChecked
      then mergeOneOption loc defs
      else if type.string == sharedDefType && allChecked
      then str.merge loc defs
      else if type.double == sharedDefType && allChecked
      then float.merge loc defs
      else mergeDefaultOption loc defs;
  };
in
  gvariant
