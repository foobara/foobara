# Foobara

Foobara is a command-based software framework with an emphasis on reflection features to facilitate integration with
other systems or subsystems. The focus of the framework is to provide these features to help
with managing domain complexity in projects with higher domain complexity. However, Foobara
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

Foobara is licensed under the Mozilla Public License Version 2.0. Please see LICENSE.txt for more info.
