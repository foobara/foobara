## [0.0.23] - 2024-12-03

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
