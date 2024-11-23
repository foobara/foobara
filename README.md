# Foobara

Foobara is a software framework meant to help with projects that have
a complicated business domain. It accomplishes this by helping to
build projects that are command-centric and discoverable, as well as some other features.

### Commands

* Foobara commands are meant to encapsulate high-level domain operations.
* They serve as the public interface to Foobara systems/subsystems.
* They are organized into Organizations and Domains.

### Discoverability
* This means there is a formal machine-readable description of the systems/subsystems
* The implication of this is that integration code can be abstracted away.

### Implications of command-centric + discoverability
* The system better communicates the mental model of the problem and the chosen solution
* Engineers are able to spend more time writing code relevant to the domain and less time
  writing code related to specific tech-stack, software pattern, or architecture decisions.
* Engineers can spend more time operating within a specific mental model at a time instead of
  multiple mental models all at once.

### Other features for helping with Domain complexity

* Domain mappers
  * These can map a concept from one domain to another.
  * This separation of concerns leads to commands that have code
    that reflects the domain they belong to as opposed to logic from many different domains.
* Remote commands
  * These have the same interface as commands that live in other systems and act as a proxy to them.
  * This allows rearchitecting of systems without changing interfaces and so reducing refactoring/testing required.
  * These currently exist for both Ruby and Typescript
* An extract-repo script
  * Can be used to extract files from one Foobara project to another, preserving history.
  * Making this easier can help with rearchitecting systems.
* Custom crud-drivers (if needed)
  * You could hypothetically write your own custom CRUD driver that knows how
    to assemble an entity record with a clean mental model from a mismodeled legacy database.

## Installation

To add foobara to an existing project, you can add `foobara` gem to your Gemfile or .gemspec as you normally would.

To create a new project using a foobara generator, you could install the `foob` gem with `gem install foob` and then
run `foob generate ruby-project --name your-org/your-new-project-name`

## Usage

You can find a code demo video and an overview video of what Foobara is at https://foobara.com

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
