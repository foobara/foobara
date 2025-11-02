This document is intended to document the rationale behind certain key decisions

<!-- TOC -->
* [2025-11-02 Decide on a meaning for a value with an atomic association-depth](#2025-11-02-decide-on-a-meaning-for-a-value-with-an-atomic-association-depth)
  * [Problem](#problem)
    * [Pros of the foobara.git interpretation](#pros-of-the-foobaragit-interpretation)
    * [Cons of the foobara.git interpretation](#cons-of-the-foobaragit-interpretation)
  * [Decision](#decision)
  * [Rationale](#rationale)
* [2024-12-08 Create a DetachedEntity type, import Entity as immutable DetachedEntity](#2024-12-08-create-a-detachedentity-type-import-entity-as-immutable-detachedentity)
  * [Problem](#problem-1)
  * [Decision](#decision-1)
  * [Concerns](#concerns)
* [2024-10-27 Release under the MPL-2.0 license](#2024-10-27-release-under-the-mpl-20-license)
  * [Decision](#decision-2)
  * [Rationale](#rationale-1)
* [2024-06-24 make code in src/ non-colliding with other projects and add src to require_paths](#2024-06-24-make-code-in-src-non-colliding-with-other-projects-and-add-src-to-require_paths)
  * [Decision](#decision-3)
  * [Rationale](#rationale-2)
* [[RETRACTED] 2024-05-31 Temporarily release under AGPLv3](#retracted-2024-05-31-temporarily-release-under-agplv3)
  * [Decision](#decision-4)
  * [Rationale](#rationale-3)
* [2024-05-30 Dual-license satellite foobara gems under Apache-2.0 OR MIT](#2024-05-30-dual-license-satellite-foobara-gems-under-apache-20-or-mit)
  * [Decision](#decision-5)
  * [Rationale](#rationale-4)
    * [Why MIT](#why-mit)
    * [Why Apache-2.0](#why-apache-20)
    * [Why Apache-2.0 OR MIT](#why-apache-20-or-mit)
    * [Other licenses that were contenders](#other-licenses-that-were-contenders)
    * [Other concern about the murky state of generative AI and copyright implications](#other-concern-about-the-murky-state-of-generative-ai-and-copyright-implications)
* [[RETRACTED] 2024-05-19 License under user choice of 3 licenses](#retracted-2024-05-19-license-under-user-choice-of-3-licenses)
  * [Decision](#decision-6)
  * [Rationale](#rationale-5)
    * [Why MIT OR Apache 2.0](#why-mit-or-apache-20)
      * [Why MIT is attractive](#why-mit-is-attractive)
      * [Why Apache 2.0 is attractive](#why-apache-20-is-attractive)
      * [Why MIT OR Apache 2.0 is attractive](#why-mit-or-apache-20-is-attractive)
    * [Why OR MPL 2.0](#why-or-mpl-20)
      * [why MPL 2.0 is attractive](#why-mpl-20-is-attractive)
      * [Why OR MPL 2.0, ie, why is MPL 2.0 scary](#why-or-mpl-20-ie-why-is-mpl-20-scary)
    * [What would have been an ideal license?](#what-would-have-been-an-ideal-license)
  * [Conclusion](#conclusion)
<!-- TOC -->

# 2025-11-02 Decide on a meaning for a value with an atomic association-depth

## Problem

There is currently inconsistency in various places around what it means to be a
value with an atomic association depth. This mostly works, regardless, because in
the monorepo (this repo), the interpretation includes more loaded data than the
interpretation in dependent repos (in particular typescript-remote-command-generator.)

Even in typescript-remote-command-generator, though, there is now inconsistencies that are
resulting in some bugs in the new castJsonResult function that is generated. It is interpretting it
as entities are loaded if they are not past a model.

Both systems get the obvious scenarios correct, namely, aggregate association-depth
really only has one reasonable interpretation (every entity record in the entire tree is loaded)
and values of types that have no reachable entities have identical aggregate and atomic
association-depth representations.

The remaining interpretations vary as follows, though:

1. In foobara.git (this repo) we interpret being an atomically-loaded value to mean
   that once we've hit an entity in the tree ov values starting at the value in question,
   we load that entity record but all records reachable from that first-encountered entity
   are not loaded.
2. In typescript-remote-command-generator.git, 
   a. In older code paths, if the type of the value in question is an entity, we load it and only it.
      All other reachable entity values in all other circumstances are unloaded.
   b. A few recently-added code paths instead mimic, or try to mimic, the foobara.git interpretation.
      They maintain a flag that indicates if we are past the first model in the structure or not.
      This differs from the other generators in the project that follow 2.a. but also differs from
      foobara.git in that crossing a model switches to primary keys, not just crossing an entity.

### Pros of the foobara.git interpretation

1. You get more data in cases where you're very likely to want that data. For example,
   what if we wanted an array of users from the backend. The foobara.git approach would
   give something like `[{id: 123, name: "Fumiko", year_of_birth: 2019}]` but the alternative
   would give `[123]`. I suspect more-often-than-not this isn't what would be desired.

### Cons of the foobara.git interpretation

1. On the flipside of the above pro, it could be that we receive a non-entity model or data structure with lots of
   very large entity records deeper within it but with no way to declare them as not-to-be-loaded.
2. It can be a little more complicated to implement, for example, in typescript-remote-command-generator.git,
   we have a ModelAtomGenerator. It uses UnloadedEntityGenerator for any entity values that are reachable from it.
   But if we wanted to implement the foobara.git interpretation, how do we know if we want the
   UnloadedEntityGenerator or the EntityAtomGenerator? To know this, we would need to know if we are past
   the first entity. it's possible we can figure this out by traversing #parent and checking each if it's
   an entity. This makes me nervous because it's more complexity to an already complex design as well
   as not sure if it will work. If we always have the type_declaration as the relevant manifest it *should*
   work but I'm not sure I want to test that and couple to it.

## Decision

For now, let's converge on the typescript-remote-command-generator.git interpretation (the old/existing one, that
if the type is an entity, we will load it, otherwise all reachable entities will be unloaded.)

## Rationale

1. Going with the load-load-the-first-entity-encountered-but-nothing-deeper approach (probably) requires
   one of several somewhat non-trivial changes to the typescript-remote-command-generator
   project generator to support it due to its design:
   a. This allows the atomic concept to serve as the least-loading-possible where needed 
      (although there still wouldn't be a way to just get a primary key that answers a question.)
   b. This does not require introducing a type of generator that represents being atomic past/before the
      first entity.
   c. Nor figuring out a way to pass extra state to the generators to let them know where they are
   d. Nor having to dig upwards through the parents of the relevant manifest to figure this out.
   Whereas foobara.git technically would require no changes, except performance improvements
   by not unnecessarily loading records that won't be used by the typescript remote commands.
2. Entities/Persistence should probably be extracted from this monorepo so we can promote
   commands/connectors/other types as a lightweight 1.0.0 version while allowing
   entities/persistence to develop and reach
   1.0.0 quality at its own pace along the way. So perfecting these concepts might not be worth prioritizing.
   So going with the simplest option that will work is probably wise.

# 2024-12-08 Create a DetachedEntity type, import Entity as immutable DetachedEntity

## Problem

Importing an Entity from system A into System B results in that Entity not
being able to:

1. Participate in/open transactions
2. Be cast to from a primary key value

This means in the importing system you have to call `SomeCommand.run!(record: record.id)` whereas
in the remote system you can call `SomeCommand.run!(record:)`.  This breaks a major design
goal of Foobara which is that commands should be able to be moved between systems without
refactoring calling code.

## Decision

Introduce a DetachedEntity Foobara type that sits between Model and Entity to house
the expected behavior.  When importing an entity, convert its declaration to detached_entity.
May as well make it immutable as well since there's no meaningful way to mutate the record.

## Concerns

I don't like the name. I can think of some potentially better naming schemes but they would require
renaming Entity. I do not want do the work of renaming Entity without being more certain
that we've settled on a good naming scheme.

# 2024-10-27 Release under the MPL-2.0 license

## Decision

Re-release under the more permissive MPL-2.0 license

## Rationale

Didn't know which license to release under and none seemed to be quite
what I wanted. MPL-2.0 seems to be be the least-of-a-bad-fit of the popular licenses.
Since I've released demos and would like people to play with it, it felt like I should
just go with a more permissive license than the temporary one I was using.

You can see old license-related decisions in this log for more details on the thought process.

# 2024-06-24 make code in src/ non-colliding with other projects and add src to require_paths

## Decision

Prior decision was to simplify things and perhaps shorten the require look ups
by only having lib/ be in require_path and it loads everything else.

This is not currently implemented in this repository but rather an external
repository in the foobara github organization. But since this decision log lives here,
recording the decision here. TODO: probably should put this decision log in its own
repository or some other shared resource besides this repository.

## Rationale

A snag I ran into is RubyMine (and perhaps other IDEs?) does not index classes that
are not in files that are in the require_path. This is really inconvenient since I instead
would have to go find documentation somewhere or the source on github instead of just
ctrl clicking to jump to the code in the IDE. I don't see a way to tell RubyMine to just
index everything. So for now, putting everything in require_path will make it reachable.

# [RETRACTED] 2024-05-31 Temporarily release under AGPLv3

## Decision

Adopting a very restrictive license temporarily

## Rationale

Unblocks demos that benefit from use of rubygems while buying time to officially finalize a licensing decision.

# 2024-05-30 Dual-license satellite foobara gems under Apache-2.0 OR MIT

## Decision

Release gems in the foobara org under Apache-2.0 OR MIT.

## Rationale

### Why MIT

* Typical license of the Ruby ecosystem
* High-compatibility with other software licenses.

### Why Apache-2.0

* Robust
* Includes patent grants

### Why Apache-2.0 OR MIT

* Maximizes contexts in which Foobara can unambiguously be used without
  much overhead or confusion.
* Reduces needs to debate less typical licensing options with users
  or contributors.
* Reduces need to relicense later for adoption's sake.
* Just Apache-2.0 results in incompatibility with GPLv2
* Just MIT does not explicitly extend patent grants.

A thought... By choosing this combination instead of MPL-2.0, then it's not
possible to use Foobara in a GPLv2 app without receiving a patent grant from the
MIT license. However, my understanding is that such a user does at least know that
all contributors have granted any patents in their contributed code to the Foobara
project itself by meeting the requirements of both licenses in order to contribute.

### Other licenses that were contenders

* MPL-2.0
  * Pros:
    * Robust
    * Compatible with GPLv2 and includes patent grants, eliminating the need to dual-license
  * Cons:
    * Not typical in the Ruby ecosystem and would result in conversations among contributors and users.
    * Could also potentially impact adoption negatively though I don't think it logically should.
  * Neutral:
    * The copyleft aspects of MPL-2.0 seem fair while still being quite permissive. However, likely irrelevant because:
      * These types of projects are typically used as unmodified libraries distributed by rubygems.
      * When there is a modification, there's not much incentive not to share those improvements. It is
        a hassle to manage a private fork and easier to just upstream improvements to avoid
        that hassle.
      * Even in the case of a private fork, typically the code winds up being used in some network service
        and not "distributed" and so the copyleft is irrelevant in these common usage patterns
    * File-level aspect.
      * Receiving a copy of the modified code is generally the normal usage pattern since it's
        an interpreted language. There are some tools for encoding but usually Ruby is interpreted from the source,
        however, the typical pattern is to receive the code.
        * Also means static-linking stuff is not relevant
      * Ruby is so easy to monkey patch. It is very easy to modify a Ruby program without modifying a specific file.
        Potentially undesirable to go down that path. Not sure. But, regardless, there are many ways to add
        important code to a code base without disturbing certain files or at least minimally disturb them.
        And, so, major improvements to code under the MPL can be made without technically triggering the copyleft
        by leaving the old code in place and hooking new code into it.
    * Makes it clear what license contributions are under (if using license headers in files.) This is because
      1) modifications to existing files are MPL-2.0 via terms of the license, regardless of contributor intent.
      2) new files can be force via the build to have license headers and therefore would express intent
         by the contributor to license the code as MPL-2.0.

      * Why irrelevant? Because github inbound=outbound convention means if the project is under X license
        then a contribution is under X license by default.
* OSL-3.0
  * Pros
    * This was the license I liked best of all the licenses I read. It felt quite fair and robust.
  * Cons
    * incompatible with not only GPLv2 but all GPL. So it's really dead-on-arrival.
    * Is not popular and hasn't been defended in court.
* EUPL and CDDL
  * Based on MPL-1.1 and not compatible with GPLv2
* LGPL
  * Not very concise especially for an interpreted language.
  * I'm worried about users incorrectly lumping it in with strong copyleft.
  * I find it interesting that GNU recommends that you don't use LGPL.
  * I think the philosophical/political views of the license authors on OSS are not really necessary
    and I'm hesitant to make it seem like it's a position communicated by a community.

### Other concern about the murky state of generative AI and copyright implications

I would like similar code generated from AI trained on code from this project, or prompted with code
from this project, to be considered a derived work.

It doesn't seem like any of the existing popular licenses influence whether or not an AI-generated work
is considered derived or not.

# [RETRACTED] 2024-05-19 License under user choice of 3 licenses

## Decision

RETRACTED: kept in the history but should relocate these thoughts to some other resource.

Release foobara gem (this repository) under the user's preference of
3 different licenses: `MIT OR Apache 2.0 OR MPL 2.0` and come up with a shorter alias for this license.

## Rationale

### Why MIT OR Apache 2.0

#### Why MIT is attractive

MIT is attractive, aside from the obvious (permissible, simple), because this license
is the typical license used in the Ruby community. Adoption would be as known-to-be-simple as possible under
this license in this ecosystem.

#### Why Apache 2.0 is attractive

Apache 2.0 is attractive due to its robustness and extending patent permissions to users.

#### Why MIT OR Apache 2.0 is attractive

Dual-licensing under both allows the end-user to operate under either as-needed.

The Rust community dual licenses under these two suggesting that a community can function under such
a licensing scheme.

Also, Bootstrap, in 2012, relicensed from Apache 2.0 to MIT so that GPLv2 projects could use Bootstrap.
Dual licensing would have also been a solution but the point here is future-proofing unexpected pressure to
relicense for adoption-sake.

### Why OR MPL 2.0

#### why MPL 2.0 is attractive

MPL 2.0 seems to me (I am not an expert on this and far from it) after some research to be a robust license
that seems to give nearly as much encouragement to give contributors back improvements to their
original efforts without sacrificing much, if any, practical permissiveness.

#### Why OR MPL 2.0, ie, why is MPL 2.0 scary

It seems like there would be no serious practical burden imposed on users by the MPL 2.0 license. But I'm not
100% certain of that without expert confirmation. And so, if users are also uncertain, that might hurt adoption
even if in actuality the license is not a hassle to users in any meaningful way.

What I mean by this is: if I have an MIT-licensed project, or a proprietary project, and I add a MPL-2.0 only gem
to my .gemspec, is there any administrative burden imposed? It seems like "no" but again I am not an expert.
If the answer is "no" but unclear to the user, that might still hurt adoption. To that extent, if confused with GPL
style licenses, it might be ruled out by some organizations even if incorrectly so.

However, making it OR MIT OR Apache 2.0 allows the user to just operate as if the project were licensed in
the way most convenient to the user among those options, making adoption, I assume, at least as easy as MIT alone.

But the real suspected benefit is this seems like it would allow MPL 2.0 to be the preferred license in the future
without needing to seek relicense permission from contributors, nor CLAs to avoid seeking relicense permission.
It is, in essence, a solution to punt and get back to coding for now and revisit with more real-world information
later.

### What would have been an ideal license?

Hard to say without being an expert on licenses and user behavior but, at this time, my best (admittedly uninformed)
guess would be to ideally use only one license, similar to MPL 2.0, but:

1) without the file-level/static stuff as it is likely irrelevant for a gem like Foobara.
2) with a network-exposure-is-distribution clause like AGPL 3.0, or really anything to maximize an
   "if you improve it and make use of those improvements, then share the improvements" vibe, which,
   with github and forks, seems like a trivial requirement to satisfy.
3) if possible, a clause stating that code generated from Foobara code as
   training data or prompt data to an AI system constitutes a derived work.

Without expertise and given the point in history where I'm making this decision, I can't really draft
such a license and even if I could that seems like it could be a bad strategy regardless (aka license proliferation)

NOTE: if you happen to know an easy way for me to access expertise for clarity on these issues, please let me know.
I'd be happy to pay for a short consult with a professional (ie lawyer who specializes in open-source licensing.)

## Conclusion

License under MIT OR Apache 2.0 OR MPL 2.0 for now to:

1) guarantee seamless fit into Ruby ecosystem (MIT)
2) extend patent-granting in case somebody wants that (Apache 2.0/MPL 2.0)
3) allow future relicensing under MPL 2.0 without CLAs or non-trivial-contributor-roundup if it turns out that MPL 2.0
   would have been a good choice once more is understood about the adoption-impact of having chosen that license.
4) stop thinking about licensing and get back to hackin'

To be clear, we are punting for now. At some point, we should choose either:

1) MPL 2.0
2) MIT OR Apache 2.0 (works for Rust community... seems there's no need to decide between these two)
3) Some other better-fitting license (would require permission from non-trivial contributors)
