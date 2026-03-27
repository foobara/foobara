Foobara is a software framework that is command-centric and discoverable.

Domain operations are
encapsulated in commands, which serve as the public interface to systems, and which automatically
provide machine-readable formal metadata about those commands.

This metadata makes your domain discoverable and can be used to abstract away integrations,
such as HTTP, CLI, MCP, whatever. It also makes your domain logic
forward-compatible with integrations you didn't know you needed or that might not even have
existed yet when you built your commands.

This metadata is also used to help export commands from one system and import them into another
as remote commands. This means you can write your domain logic and automatically get a Ruby SDK or Typescript SDK for
free.

This also helps with rearchitecting efforts since a remote command has the same interface
as the local command. Domain logic refactors are not required to relocate domain logic
in/out of other systems. And this also helps a system communicate and impose its mental model
on consuming systems.

You can use Foobara as a full standalone framework or you can use it with existing code
as a service-objects layer and leverage the integration features of Foobara when/if necessary.

<!-- TOC -->
* [Overview of Features/Concepts/Goals](#overview-of-featuresconceptsgoals)
  * [Command-centric](#command-centric)
  * [Discoverability](#discoverability)
  * [Implications of command-centric + discoverability](#implications-of-command-centric--discoverability)
  * [Other features for helping with Domain complexity](#other-features-for-helping-with-domain-complexity)
* [Installation](#installation)
* [Usage/Tutorial](#usagetutorial)
  * [Foobara 101](#foobara-101)
    * [Commands](#commands)
    * [Organizations and Domains](#organizations-and-domains)
    * [Types](#types)
    * [Models](#models)
    * [Entities](#entities)
    * [Command connectors](#command-connectors)
      * [Command-line connectors](#command-line-connectors)
      * [HTTP Command Connectors](#http-command-connectors)
        * [Rack Connector](#rack-connector)
        * [Rails Connector](#rails-connector)
      * [MCP Command Connector](#mcp-command-connector)
      * [Async Command Connectors](#async-command-connectors)
      * [Scheduler Command Connectors](#scheduler-command-connectors)
  * [Intermediate Foobara](#intermediate-foobara)
    * [Metadata manifests for discoverability](#metadata-manifests-for-discoverability)
    * [Remote Commands](#remote-commands)
    * [Subcommands](#subcommands)
    * [Custom Errors](#custom-errors)
      * [Input Errors](#input-errors)
      * [Runtime Errors](#runtime-errors)
  * [Advanced Foobara](#advanced-foobara)
    * [Domain Mappers](#domain-mappers)
    * [Types](#types-1)
      * [Builtin types](#builtin-types)
      * [Custom types](#custom-types)
    * [Code Generators](#code-generators)
      * [Generating a new Foobara Ruby project](#generating-a-new-foobara-ruby-project)
      * [G

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'foobara'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install foobara
```