# Review tips

[Code Review Antipatterns]: https://www.chiark.greenend.org.uk/~sgtatham/quasiblog/code-review-antipatterns/
[nixpkgs]: https://github.com/NixOS/nixpkgs
[SNUG Discord server]: https://discord.gg/6rMPtKDKzt
[multi-trip reviews]: #2-single-trip-reviews

An often overlooked part of contributing to an open source project is proper
review practices. It's very easy to alienate contributors with bad code review.
Of course, nobody will get this right _all_ of the time. Rather, this guide aims
to encourage some good practices to make Hjem Rum a better environment for
contributors.

If you notice another contributor not following these, don't call them out
publicly―choose instead to respectfully message them via private channels. These
tips serve as a reference, not a rule of law.

<sub>Much of this guide is inspired by [Code Review Antipatterns] by Simon
Tatham. If you're interested, give it a look! </sub>

## 1. Be nice

Starting off with an easy one! However, there's actually something meaningful to
be said here. As a reviewer, it's easy to get frustrated with constantly giving
the same feedback. If you find yourself giving feedback like:

> Use ____.

Instead, maybe phrase it as:

> Could you change this to ____?

This might sound silly at first. But when it feels like a reviewer is _on your
side_, it makes a huge difference. If this tone feels a little foreign, pretend
you're writing an email, and that should give you a good barometer.

## 2. Single-trip reviews

As a contributor, it can be frustrating to finish accommodating all the review
comments, only to immediately be given a bunch of other suggestions, which
could've easily been included in the first review session. As a reviewer, take a
moment and think―if these review comments were accommodated, would you be happy
to merge this? If not, you might want to add something else to the review―or you
might leave the contributor with unnecessarily high hopes.

Part of this is also communicating big problems early on. Imagine if, as a
contributor, you have been responding to review comments for ages and are hoping
things are actually getting close to being merged. Only suddenly, the reviewer
tells you:

> I actually don't like any of this, and want it completely redone.

Or:

> I don't think this is a good idea for the project.

How would that feel? As a reviewer, it's best to temper expectations. If
something will require a lot of changes to be mergeable, be up-front about
it―even if you feel a little guilty. Better to rip the bandaid off now, than to
leave it on for a few review sessions.

## 3. United front

Anyone who's contributed to [nixpkgs] knows the cycle―you've accommodated one
reviewer's comments, only for a different reviewer to come in with MORE things
to change. Or, even worse―maybe reviewer 2 disagrees with reviewer 1―and now
they're fighting on your PR.

When possible, try to coordinate review feedback. The [SNUG Discord server] is a
great place for working together to ensure feedback is clear and consistent
between reviewers.

## 4. Bikeshedding

Have you ever made a PR, only for every single line to be criticized for not
being done exactly how the reviewer wants? It feels like your code is being held
to an impossibly high standard. Reviewers often view code more harshly―after
all, they're the arbiter of whether some piece of code makes it into the
project. But this alienates contributors―especially when this is combined with
[multi-trip reviews]. It ends up feeling like your code is being held hostage,
until the maintainer declares it _perfect_.

To prevent this as a reviewer, there are a few ways to determine whether you, or
someone else, might be bikeshedding.

1. Are the standards you're requesting to be followed actually written down in
   the documentation? If not, is the unwritten standard consistently followed in
   the existing codebase? If neither of these are true, maybe you shouldn't put
   this on a random contributor.
2. Is it **blocking**? A stylistic change might be nice to have, but could be
   merged without it. Maybe you as the reviewer could make the patch yourself
   after the PR is merged, to take the work off the contributor.
3. Is your requested change part of code actually introduced by this
   contributor? Maybe you never noticed that this part of the code is a little
   ugly, or uses a paradigm you don't love. But this code wasn't changed by the
   contributor―you only noticed it because their changes touched the same file.
   Rather than putting this work on the contributor, who just wants _their_
   change in, maybe just make this patch separately.

Sometimes, a _little_ bikeshedding isn't that big of a deal―if you've worked
with this contributor before and think they'll be fine with a few stylistic
nitpicks, then mentioning a stylistic change is probably fine. But when
bikeshedding does happen, try to treat it as _optional_. Rather than saying:

> Please do ___.

Maybe, if it's a stylistic change, say:

> Stylistic nitpick, but could you maybe change this to ____? Not blocking.

# Extending this document

If you find yourself experiencing something as a contributor that makes you less
motivated to contribute―whether it's for Hjem Rum or some other project―feel
free to make a PR extending this document. Proper code review practices keep
contributors around, which is how an open source project thrives. Code review
will never be perfect, but it can be better.
