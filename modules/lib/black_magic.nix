{lib}: let
  inherit
    (builtins)
    filter
    isAttrs
    isNull
    isString
    concatLists
    head
    readDir
    mapAttrs
    length
    hasAttr
    getAttr
    concatStringsSep
    attrNames
    attrValues
    ;
  inherit
    (lib.attrsets)
    mapAttrsToList
    showAttrPath
    attrByPath
    mergeAttrsList
    filterAttrs
    recursiveUpdate
    ;
  inherit
    (lib.lists)
    last
    drop
    dropEnd
    fold
    ;
  inherit (lib.modules) evalModules;
  /**
  This is effectively (builtins.tail list), however even the docs themselves state
  to avoid that function due to an operation cost of O(n) instead of O(1) per call.

  tail :: [ T ] -> [ T ]
  */
  tail = list: (drop 1 list);
  /**
   A bit of terminology to prevent possible confusion of myself and others in the future:
   path: An attribute path,
   	e.g.
   		{ a = { b = "c"; }; } => [ "a" "b" ]
   	or
   		{ a = { b = mkOption {...}; }; } => [ "a" "b" ]

   filetree:
   	Just your regular directory with possibly nested directories.
   filetree != path (in this context)

   Some custom types used throughout the annotations:

   filetree :: { ${pathComponent} :: (filetree | ${file}}) }
   attrPath :: [ string ]
  moduleResolutionResult :: {	resolved :: [ ${filepath} ]; unresolved :: [ ${attrPath} ] }
  */

  resolveFileTreeRecursive = path: let
    dirItems = readDir path;
  in
    mapAttrs (
      name: value: let
        ItemPath = path + ("/" + name);
      in
        if value == "directory"
        then resolveFileTreeRecursive ItemPath
        else ItemPath
    )
    dirItems;

  /**
  pop the last element from the list

  pop :: [ T ] -> [ T ]
  */

  /**
  If the current attrset is a final value, return an empty path as there are no child paths.
  Else, recurse into each child value, get their paths, add the child name to the path,
  and combine all child paths into one list

  getAttrPaths' :: { ... :: ?; _type ? :: string } -> [ attrPath | [ string | 1 ] ]
  */
  getAttrPaths' = attrset:
    if !(isAttrs attrset) || (attrset ? _type && isString attrset._type)
    then
      if isAttrs attrset && attrset._type == "if"
      then [[1]] # No fucking idea what do do here instead of throwing, I dont think this can happen though.
      else [[]]
    else
      concatLists (
        mapAttrsToList (name: value: map (path: [name] ++ path) (getAttrPaths' value)) attrset
      );

  /**
  getAttrPaths' but with checking

  getAttrPaths :: { ... :: ?; _type ? :: string } -> [ attrPath ]
  */
  getAttrPaths = set:
    map (
      path:
        if (last path) == 1
        then throw "Encountered mkIf value at ${showAttrPath (dropEnd 1 path)}"
        else path
    ) (getAttrPaths' set);

  pathToAttr = path: value:
    if (length path) > 0
    then {"${head path}" = pathToAttr (tail path) value;}
    else value;
in {
  /**
  Take a deferredModule, and use it to determine what modules need loading
      resolveModulesFromLazyModule :: { modulesDir :: Path; deferredModule :: deferredModule; rumLib :: rumLib; extraModules ? :: [ module ] } -> [ module ]
  */
  resolveModulesFromLazyModule = {
    modulesDir,
    deferredModule,
    rumLib,
    extraModules ? [],
    options,
  }: let
    moduleFileTree = resolveFileTreeRecursive modulesDir;
    /**
    To collect the paths of files to import we need to do a couple things:
    - ~~Figure out the attrPaths to the bottommost option declarations~~ 6 months later; what does this even mean??? ( 2(?) months after, I still dont know what I was yapping about )
    - Consider mkIf's
    - Make sure to filter (Filter *what* ??????)
    */

    /**
    Attempt to resolve all used config values without a matching option into filepaths pointing to modules

    resolveLazyModules :: { config :: ?; options :: ? } ->  moduleResolutionResult
    */
    resolveLazyModules = {
      config,
      options,
      ...
    }: let
      /**
      All config values that dont have a matching option (?)

      freeformAttrPaths :: [ attrPath ]
      */
      freeformAttrPaths = filter (
        path: let
          maybeOption = attrByPath path null options;
        in
          !(isAttrs maybeOption && maybeOption ? _type && maybeOption._type == "option")
      ) (getAttrPaths config);

      /**
      Recurse into each part of a path and try to resolve it to a file, returning null when unsucessful

      resolvePathToModule' :: attrPath -> { ...: string } -> string | null
      */
      resolvePathToModule' = path: filetree: let
        headElem = head path;
      in
        if hasAttr headElem filetree
        then let
          subtree = getAttr headElem filetree;
        in
          assert (isAttrs subtree);
            resolvePathToModule' (tail path) subtree
        else let
          fileHeadElem = headElem + ".nix";
        in
          if hasAttr fileHeadElem filetree
          then let
            file = getAttr fileHeadElem filetree;
          in
            assert isString file; file
          else if filetree ? "default.nix"
          then filetree."default.nix"
          else null;

      /**
      Resolve an attrPath to a module file.
      Return format: { "attr.path.seperated.with.dots" = "file/or/null/if/file/doesn't/exist.nix"}

      resolvePathToModule :: attrPath -> { ${attrPath} :: string | null }
      */
      resolvePathToModule = path: {
        "${concatStringsSep "." path}" = resolvePathToModule' path moduleFileTree;
      };

      /**
      All resolved and unresolved module files

      allModules :: { ${attrPath} :: string | null }
      */
      allModules = mergeAttrsList (map resolvePathToModule freeformAttrPaths);

      /**
      Get it? because you filter for all items "where Value is [what]". e.g. all items where Value is String

      whereValue :: (? -> bool) -> { ... :: ? } -> { ... :: ? }
      */
      whereValue = isWhat: filterAttrs (_: isWhat);

      out = {
        resolved = attrValues (whereValue isString allModules);
        unresolved = attrNames (whereValue isNull allModules);
      };
    in
      out;

    /**
    iterate :: [ module ] -> { config :: { ... :: ? }; options :: { ... :: ? } }
    */
    iterate = resolvedModules:
      evalModules {
        modules =
          resolvedModules
          ++ [
            deferredModule
            (
              let
                opts = removeAttrs options ["_module"];
              in {
                _file = "${__curPos.file}:${builtins.toString __curPos.line}";
                options = opts;

                config = {
                  _module = {
                    freeformType = lib.types.attrs;
                    args = {inherit rumLib;};
                  };
                };
              }
            )
          ];
      };
    /**
    converge :: [ module ] -> moduleResolutionResult -> Int -> { config :: { ... :: ? }; unresolved :: [ string ] }
    */
    converge = resolvedModules: prevAllModules: limit:
      if limit == 0
      then throw "Module evaluation did not converge after iteration limit"
      else let
        current = iterate prevAllModules.resolved;
        currentAllModules = resolveLazyModules current;
      in
        if (length currentAllModules.resolved) == 0
        then {
          config = current.config;
          inherit (currentAllModules) unresolved;
        } # Converged
        else converge (resolvedModules ++ currentAllModules.resolved) currentAllModules (limit - 1);

    /**
    converged :: { config :: { ... :: ?}; unresolved :: [ string ] }
    */
    converged = converge extraModules {resolved = [];} 20;

    /**
    config :: { ... :: ? }
    */
    config =
      if (length converged.unresolved) > 0
      then throw "Hjem-Rum: Couldn't find module(s) matching the following configuration value(s) \n ${converged.unresolved}"
      else converged.config;

    /**
    `config`, filtered to only include values that match non-rum options. (i.e. hjem options)
    Yes, this basically is the same logic as for `freeformAtrrPaths`, except the filter inverted

    finalConfigAttrPaths :: { ... :: ? }
    */
    finalConfigAttrPaths = filter (
      path: let
        maybeOption = attrByPath path null options;
      in (isAttrs maybeOption && maybeOption ? _type && maybeOption._type == "option")
    ) (getAttrPaths config);

    finalConfig = fold recursiveUpdate {} (
      map (path: pathToAttr path (attrByPath path null config)) finalConfigAttrPaths
    );
  in
    finalConfig;
}
