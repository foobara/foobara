
<!-- TOC -->
* [What is/Why Foobara?](#what-iswhy-foobara)
  * [Commands](#commands)
  * [Discoverability](#discoverability)
  * [Implications of command-centric + discoverability](#implications-of-command-centric--discoverability)
  * [Other features for helping with Domain complexity](#other-features-for-helping-with-domain-complexity)
* [Installation](#installation)
* [Usage/Tutorial](#usagetutorial)
* [Additional learning materials/Documentation](#additional-learning-materialsdocumentation)
* [Contributing](#contributing)
  * [Developing locally](#developing-locally)
  * [Monorepo Structure](#monorepo-structure)
* [Licensing](#licensing)
<!-- TOC -->

# What is/Why Foobara?

Foobara is a software framework meant to help with projects that have
a complicated business domain. It accomplishes this by helping to
build projects that are command-centric and discoverable, as well as some other features.

## Commands

* Foobara commands are meant to encapsulate high-level domain operations.
* They serve as the public interface to Foobara systems/subsystems.
* They are organized into Organizations and Domains.

## Discoverability

* This means there is a formal machine-readable description of the systems/subsystems
* The implication of this is that integration code can be abstracted away.

## Implications of command-centric + discoverability

* The system better communicates the mental model of the problem and the chosen solution
* Engineers are able to spend more time writing code relevant to the domain and less time
  writing code related to specific tech-stack, software pattern, or architecture decisions.
* Engineers can spend more time operating within a specific mental model at a time instead of
  multiple mental models all at once.

## Other features for helping with Domain complexity

* Domains and Organizations
  * Domains are namespaces of Commands, types, and errors
    * Domains (and commands) have explicit, unidirectional dependencies on other domains
  * Organizations are namespaces of Domains
* Domain mappers
  * These can map a concept from one domain to another
  * This separation of concerns leads to commands that have code
    that reflects the domain they belong to as opposed to logic from many different domains
* Remote commands
  * These have the same interface as commands that live in other systems and act as a proxy to them
  * This allows rearchitecting of systems without changing interfaces and so reducing refactoring/testing required
  * These currently exist for both Ruby and Typescript
* Code generators
  * Similar to remote commands, discoverability enables other types of tooling, including code generators,
    documentation tools, etc
* An extract-repo script
  * Can be used to extract files from one Foobara project to another, preserving history
  * Making this easier can help with rearchitecting systems
* Custom crud-drivers (if needed)
  * You could hypothetically write your own custom CRUD driver that knows how
    to assemble an entity record with a clean mental model from a mismodeled legacy database

# Installation

To add foobara to an existing project, you can add `foobara` gem to your Gemfile or .gemspec as you normally would.

To create a new Ruby project using a foobara generator, you could install the `foob` gem with `gem install foob` and then
run `foob generate ruby-project --name your-org/your-new-project-name`

To create a new Typescript React project using a foobara generator, you could install the `foob` gem with `gem install foob` and then
run `foob generate typescript-react-project --project-dir your-org/your-new-project-name`

And then you can import remote commands/types/domains/errors from an existing Ruby foobara backend using:

`foob g typescript-remote-commands --manifest-url http://your.foobara.ruby.backend/manifest`

And you can also automatically generate some forms for your commands as a nice starting-point with:

`foob g typescript-react-command-form --command-name SomeOrg::SomeDomain::SomeCommand`

# Usage/Tutorial

IN PROGRESS

# Additional learning materials/Documentation

* Overview and code demo videos:
  * https://foobara.com/videos
  * https://www.youtube.com/@FoobaraFlix
* YARD Docs
  * All docs combined: https://docs.foobara.com/all/
  * Per-repository docs: https://foobara.com/docs


# Contributing

Probably a good idea to reach out if you'd like to contribute code or documentation or other
forms of help. We could pair on what you have in mind and you could drive or at least we can make sure
it's a good use of time. I can be reached at azimux@gmail.com

You can contribute via a github pull request as is typical

Make sure the test suite and linter pass locally before opening a pull request

The build will fail if test coverage is below 100%

## Developing locally

You should be able to do the typical stuff:

```bash
git clone git@github.com:foobara/foobara
cd foobara
bundle
rake
```

And if the tests/linter pass then you could dive into modifying the code

## Monorepo Structure

Foobara is split up into many projects

Many are in separate repositories which you can see at: https://github.com/orgs/foobara/repositories

This repository, however, is a monorepo. Sometimes projects are extracted from here
into their own repositories. Each project in this repository has its own directory in the projects/ directory.

# Licensing

Foobara is licensed under the Mozilla Public License Version 2.0. Please see LICENSE.txt for more info.
