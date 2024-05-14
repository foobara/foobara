# Foobara

Foobara is a command-based software framework with an emphasis on reflection features to assist with
metaprogramming to facilitate integration with other systems or subsystems. The goal of these two emphasized
features is to help manage domain complexity in projects with higher domain complexity, however, Foobara
is also expected to be pleasant for use in projects with simpler domains as well.

## Installation

To add foobara to an existing project, you can add `foobara` gem to your Gemfile or .gemspec as you normally would.

To create a new project using a foobara generator, you could install the `foob` gem with `gem install foob` and then
run `foob generate ruby-project --name your-org/your-new-project-name`

## Usage

TODO: Write usage instructions here or defer to some tutorial somewhere

## Contributing

Can contribute via a github pull request as is typical but see info about licensing below first.

Make sure the test suite and linter pass locally before opening a pull request.
The build will fail if test coverage is below 100%.

It might be a good idea to reach out for advice if unsure how to chip away at the part of this project
that you are interested in.

### Developing locally

You should be able to run `bundle install` and then `rake` to run the test suite and the linter.

### Monorepo Structure

Foobara is split up into many projects. Many are in separate repositories. This repository however is unique
in the Foobara ecosystem of projects because it is a monorepo. Sometimes projects are extracted from here
into their own repositories.

Each project has its own directory in the projects/ directory.

### Licensing

My intention is to either release this under the MIT license or the Apache 2.0 license or under both with the
user being allowed to decide which license they wish to use.

Other projects in the Foobara ecosystem use the MIT license and my inclination is to use
Apache 2.0 for this repository. It would be nice if there could be a way to state that if
source code contributed to this project is used as input to AI systems, either as prompt input or training data,
to generate similar projects, that that output would be considered a derived work and therefore subject to the
license choice of this project. I'm assuming that's not a possibility.

But I am hesitant to choose between MIT and Apache 2.0 and some other hypothetical license that doesn't yet exist
for those reasons.

If you are interested in making serious contributions to Foobara, please reach out to me, and I will
likely prioritize licensing this project under one or both of the licenses mentioned above.
