# Contributing: Extending Hjem Rum's Library {#contributing-extending-hjem-rum-library}

Rather than having functions scattered throughout the module collection, we
would rather keep our directories organized and purposeful. Therefore, all
custom functions should go into our extended lib, found at `modules/lib/`.

The most common functions that might be created are a `generator` and `type`
pair. The former should be prefixed with "to" to maintain style and describe
their function: conversion _to_ other formats. For example, `toNcmpcppSettings`
is the function that converts to the format required for ncmpcpp settings.

Likewise, types should be suffixed with "Type" to maintain style and describe
their function. For example, `hyprType` describes the type used in `settings`
converted to Hyprlang.

When it comes to directory structure, you should be able to infer how we
organize our lib by both our folder structure itself as well as the names of
functions. For example, {option}`rumLib.types.gtkType` is found in
`lib/types/gtkType.nix`. In cases where a file is a single function, always be
sure to make sure the name matches the file.

If a program uses multiple functions of the same kind (e.g. two generators), you
can put them in one file, like is done in `lib/generators/gtk.nix`.

Additionally, please follow how lib is structured in Nixpkgs. For example, the
custom function `attrsNamesHasPrefix` is under `attrsets` to signify that it
operates on an attribute set, just like in Nixpkgs.
