# Quirks, Tips, & Tricks {#quirks-tips-tricks}

[#17]: https://github.com/snugnug/hjem-rum/issues/17

As you are getting familiar with Hjem Rum, you may find some strange quirks that
you are unfamiliar with. This is especially so as unlike Home Manager, the
underlying toolset implementation is a wholly separate project, with Hjem Rum
serving only as a module collection on top of Hjem.

To help alleviate this, here are some of those quirks that you may find, as well
as some tips to help you on your journey with Hjem Rum.

## Environmental Variables {#ch-environmental-variables}

Hjem provides the option {option}`environment.sessionVariables` allowing the
user to set environmental variables to be sourced. However, Hjem does not have
the capability to actually source them. This can be done manually by the user,
but Hjem Rum integrates it directly into our modules. For example, if you use
Hjem Rum to install and configure zsh, your sessionVariables set in Hjem will be
made available.

Currently, some of our modules may add environmental variables (such as our GTK
module), but cannot load them without the use of another module. Currently,
modules that load environmental variables include:

- `rum.programs.fish.enable`
- `rum.programs.nushell.enable`
- `rum.programs.zsh.enable`
- `rum.desktops.hyprland.enable`

If you are either using something like our GTK module, or are manually adding
variables to {option}`environment.sessionVariables`, but are neither loading
those variables manually, or using one of the above modules, those variables
will not be loaded. This will likely cause you problems. For example, GTK
applications may not respect your theme, as many rely on the environmental
variable to actually use the theme you declare.

Please see [#17] for status on providing support for shells and compositors. If
your shell or compositor is on listed there, please leave a comment and it will
be added. You are encouraged to open a PR to help support your shell or
compositor if possible.
