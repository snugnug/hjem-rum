# Hjem Rum \[ˈjɛmˀ ˈʁɔmˀ\][^1]

[Hjem]: https://github.com/feel-co/hjem
[Danish IPA]: https://en.wikipedia.org/wiki/Help:IPA/Danish
[source]: https://github.com/snugnug/hjem-rum/tree/main/modules/collection
[discussions]: https://github.com/snugnug/hjem-rum/discussions
[documentation]: https://rum.snugnug.org
[our docs]: https://rum.snugnug.org/contributing/introduction.html
[@NotAShelf]: https://github.com/NotAShelf
[@éclairevoyant]: https://github.com/eclairevoyant
[contributors]: https://github.com/snugnug/hjem-rum/graphs/contributors
[Home Manager]: https://github.com/nix-community/home-manager
[GPLv3]: https://www.gnu.org/licenses/gpl-3.0.en.html
[license at the top level of our codebase]: https://github.com/snugnug/hjem-rum/blob/main/LICENSE
[CC-BY-NC-SA 4.0]: https://creativecommons.org/licenses/by-nc-sa/4.0/
[license within the documentation directory]: https://github.com/snugnug/hjem-rum/blob/main/docs/manual/LICENSE

A module collection for managing your `$HOME` with [Hjem].

[^1]: Please see Wikipedia's article on [Danish IPA]. Alternatively, a rough
    English phonetic transcription would be _Yem Room_, with _room_ pronounced a
    bit closer to _rawm_.

## A brief explanation

> [!WARNING]
> Hjem Rum is currently considered alpha software―here be dragons. While many of
> us currently use its modules in our NixOS configurations, that does not mean
> it will necessarily offer a seamless experience yet, nor does it mean there
> will not be breaking changes (there will). As Hjem Rum continues to grow and
> evolve, it should become more stable and expansive, but please be patient as
> it is a hobby project. Furthermore, Hjem, the tooling Hjem Rum is built off
> of, is still unfinished and missing critical features, such as services. Hjem
> Rum is still useable, but it is not for the novice user.

Built off the Hjem tooling, Hjem Rum (loosely translated to "rooms of a home")
is a collection of modules for various applications intended to simplify `$HOME`
management for usage and configuration of applications.

Hjem was initially created as a streamlined implementation of the `home`
functionality that Home Manager provides. Hjem Rum, in contrast, is intended to
provide an expansive module collection as a useful abstraction for users to
configure their applications with ease, recreating Home Manager's complete
functionality.

## Frequently Asked Questions (FAQ)

Have any questions? Please read ahead.

**Q.** Is Hjem just a cleaner Home Manager?

**A.** You can think of Hjem as "Home Manager without modules." It is also a
cleaner implementation yes. The decision to make Hjem "Home Manager without
modules" was done for two reasons: firstly, in order to reduce evaluation times
for the core toolset. When using Hjem by itself, evaluation/build time is much
less than using Home Manager, since the entire module collection does not need
to be evaluated. The second reason was to streamline the implementation. Because
Hjem is _just_ the management of user files and services, it is easier to
optimize the implementation and continue maintenance, without the overhead of
the entire module collection sharing the same repository. Ultimately, Hjem
leaving out the modules makes it lighter for both users and developers.

**Q.** So then why does Hjem Rum exist?

**A.** Hjem Rum exists to fill the gap that Hjem leaves in $HOME management.
While the bare implementation that Hjem provides is useful for those that have
an intimate understanding of NixOS, the average user needs a cleaner, more user
friendly interface between NixOS and Hjem. If Hjem is "Home Manager without
modules," Hjem Rum are the modules that are added on top of Hjem. This means
easy to use options like `programs.alacritty.enable` and
`programs.alacritty.settings` that automatically install the program, configure
it to your liking, and integrate it into other programs you manage with Hjem
Rum.

**Q.** If Hjem Rum just adds the modules back, why would I use it instead of
Home Manager?

**A.** Hjem Rum was built from the ground up with more sane and unopinionated
practices and defaults, intending to minimize overhead and streamline the
codebase, even at the cost of development time. The goal of Hjem Rum is to
minimize technical debt and produce something that uses the optimized Hjem to
manage $HOME in a much cleaner fashion that makes it more maintainable in the
long term. Just as Hjem's lack of modules allows its implementation to be
streamlined, we hope that Hjem Rum's distance from the underlying toolset allows
its implementation to be similarly streamlined. Furthermore, if Hjem is brought
into Nixpkgs, Hjem Rum can easily serve as an external module set, not further
bloating Nixpkgs, without requiring extensive refactoring.

**Q.** What if I don't want the modules?

**A.** If you don't want to use our supplied modules and instead write your own
or even forgo wrapping `files` and `packages` entirely, we strongly encourage
you to just use Hjem on its own! If that route interests you, we also encourage
you to take a look through this repository to view the [source] of Hjem Rum's
modules. You can certainly learn a lot from our code, even if you do not wish to
use it.

**Q.** Okay, you've sold me. Is there an easy way to migrate from Home Manager
to Hjem Rum?

**A.** Unfortunately, there is no shortcut―you'll have to do it manually.
However, because Hjem Rum's API is not too different from Home Manager's, it is
thankfully not too difficult. The most burdensome part would be moving your
module configuration from Home Manager modules into your NixOS or Hjem Modules,
and changing the names of the option calls.

**Q.** Do you support Darwin/Standalone?

**A.** The question of supporting Nix Darwin and Standalone is more a matter of
what Hjem supports. At the moment, Hjem supports neither Darwin nor Standalone,
and so Hjem Rum does not either. However, both are on the table for the
development of Hjem, and Hjem Rum would follow suit if compatibility was added.

_Still_ confused? Go ahead and leave a question in [discussions].

## Usage and Documentation

Hjem Rum includes a full set of documentation, including an options search
system. Please see our [documentation] for both guides on installing Hjem Rum
and a full list of options that you can configure programs with.

## Contribution

If you are interested in contributing to Hjem Rum, please check out our
contributing guidelines on [our docs]. We are always interested in
contributions, particularly as Hjem Rum is a project with an inherently enormous
scope. If you are new, unfamiliar, or otherwise scared of trying to contribute,
please know that any contribution helps, big or small, and that reviewers are
here to help you contribute and write good code for this project.

## Credits

Credit goes to [@NotAShelf] and [@éclairevoyant] for creating Hjem.

We would also like to give special thanks to all [contributors], past and
present, for making Hjem Rum what it is today.

Additionally, we would like to thank everyone who has contributed or maintained
[Home Manager], as without them, this project likely would not be possible, or
even be conceived.

## Licenses

All the code within this repository is protected under the [GPLv3] license
unless explicitly stated otherwise within a file. Please see the
[license at the top level of our codebase] for more information.

Additionally, all of our documentation, including this file, is protected under
[CC-BY-NC-SA 4.0], as according to the
[license within the documentation directory].
