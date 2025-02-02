## [0.0.55] - 2025-02-01

- Mark types as builtin directly and add builtin flag to manifest
- Pass Request#inputs through to Describe and other commands
- Fix bugs around what is considered a manifest entity/model

## [0.0.54] - 2025-01-31

- Change interface of base_type_for_manifest

## [0.0.53] - 2025-01-30

- Prefix and re-organize several model methods to facilitate type extension
- Add support for generating a manifest with detached entities based on context

## [0.0.51] - 2025-01-26

- Add a Type#remove_processor_by_symbol method to help with certain situations when defining custom types

## [0.0.50] - 2025-01-22

- Fill out more foobara_ model attribute helper methods to further support the ActiveRecordType gem

## [0.0.48] - 2025-01-17

- Add support for foobara_attributes_type to allow ActiveRecordType gem to work

## [0.0.47] - 2025-01-03

- Bumped Ruby from 3.2.2 to 3.4.1
- Allow passing in a module when registering a "builtin" type

## [0.0.42] - 2024-12-23

- Add a Domain.domain_through_modules helper

## [0.0.41] - 2024-12-19

- Allow marking a project as a project from outside of the monorepo

## [0.0.39] - 2024-12-18

- Introduce processor .requires_type? concept and extract PrimaryKey caster to a proper location
- Make mutable a supported processor

## [0.0.38] - 2024-12-11

- Make DomainMappers extend Command so they have possible errors and statefulness/a cleaner API
- Fixup domain mapper lookups to give proper values/errors in various scenarios, particularly in the context
  of running a subcommand

## [0.0.36] - 2024-12-10

- Fix bug with command-named convenience functions
- Make domain mappers cast their inputs
- Exclude detached entities from associations

## [0.0.33] - 2024-12-09

- Introduce a DetachedEntity concept that sits between Model and Entity
- Add a detached_to_primary_key flag to EntitiesToPrimaryKeysSerializer
- Create command-named convenience functions for .run! calls

## [0.0.30] - 2024-12-07

- Fix problems with extending models/entities
- Add a mutable class helper for models and improve mutable
  use a bit
- Fix bug when passing an unregistered Type instance to .foobara_registered?

## [0.0.28] - 2024-12-05

- Make Domain#foobara_depends_on? give a more intuitive answer

## [0.0.27] - 2024-12-04

- Add some Error DSL convenience methods (symbol/message/context)

## [0.0.26] - 2024-12-03

- Add error defaults for message and context
- Support registering possible runtime errors by symbol
- Make sure errors created via Command.possible_*error are namespaced to that command
- Allow passing all Error subclass parameters into possible_*error calls
- Allow creating entity types from declaration without model_module
- Make model classes with an mutable of false have instances that default to immutable

## [0.0.21] - 2024-12-02

- Allow #foobara_manifest to be called without a to_include Set

## [0.0.20] - 2024-12-01

- Fix delayed_connections bug in command connector

## [0.0.19] - 2024-11-30

- Add some noop crud driver method implementations to
  make implementing simple crud drivers easier
- Allow serializers to be created without declaration_data

## [0.0.17] - 2024-11-22

- Fix bug where mutable not being set explicitly raises
- Also, make it so models don't default to mutable false when processed by a model type
- Add a Transaction#perform convenience method

## [0.0.15] - 2024-11-20

- Move entity attributes type declaration helpers from Command::EntityHelpers to Entity for convenience.

## [0.0.14] - 2024-11-15

- Provide a default execute because why not...
- Allow require "foobara" instead of require "foobara/all"

## [0.0.13] - 2024-11-13

- Do not fail :one_of if it is nil and :allows_nil

## [0.0.12] - 2024-10-30

- Support delayed command connection

## [0.0.11] - 2024-10-27

- Release under the MPL-2.0 license

## [0.0.10] - 2024-10-26

- Extract http command connector to a different repostiory

## [0.0.9] - 2024-09-11

- Add CommandRegistry#size

## [0.0.8] - 2024-08-23

- Add a couple more entity attribute convenience helpers to commands

## [0.0.7] - 2024-08-21

- Add Manifest::Type#builtin?

## [0.0.6] - 2024-08-21

- Give a way to check if a type is builtin by reference

## [0.0.5] - 2024-08-21

- Render element type for Array types in Http::Help

## [0.0.4] - 2024-08-19

- Render element type for Array types in Http::Help

## [0.0.3] - 2024-08-15

- Do not automatically try to map subcommand types to calling command result type
- Add some crude help info for models in http connector

## [0.0.2] - 2024-06-20

- Make sure content-type is json if we are json serializing an HTTP response

## [0.0.1] - 2024-05-31

Very very alpha alpha release for convenience of demoing the project.

- Temporarily released under a restrictive license (AGPL-3.0) to unblock demoing while
  a permissive license is officially decided on.

## [0.0.0] - 2023-06-14

- Project birth
