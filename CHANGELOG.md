# [0.0.125] - 2025-05-15

- Create a yaml inputs sugar

# [0.0.124] - 2025-05-14

- Fix bug creating multiple exposed domains instead of just one

# [0.0.123] - 2025-05-14

- Allow type name strings as type declarations as a fallback instead of only symbols

# [0.0.122] - 2025-05-13

- Add command connector sugar features and implement several command connector sugars

# [0.0.121] - 2025-05-11

- Handle gnarly bugs that arise when creating a custom type named model (or entity or detached_entity)

# [0.0.120] - 2025-05-11

- Fix a race condition in persistence
- Fix various problems preventing sensitive/private types from being properly removed
  in exposed types

# [0.0.119] - 2025-05-08

- Make anonymous transformers more deterministic in manifests
- Remove delegates and private attributes from exposed models
- Make sure delegated attributes make it out through aggregate serializers

# [0.0.118] - 2025-05-07

- Fix bug preventing allow_nil from being used with entities
- Fix bugs with .all and .load
- Fix bug with possible error class lookups for tuple types

# [0.0.117] - 2025-05-05

- Make sure we do not apply an authenticator unless it is applicable
- Move loaded/unloaded concept up into DetachedEntity from Entity
  - This allows us to deal with serialization of detached entities as their primary keys
- Fix bugs preventing connecting/importing types with delegated attributes

# [0.0.116] - 2025-05-03

- Add automatic transaction support to requests, cover in/out mutators/transformers
  - This makes it so that authenticators and allowed rules can more cleanly be
    expressed when they have the same entity bases needed by the transformed command
- Move #authenticated_user from TransformedCommand to Request
- Add a Request#authenticated_credential
- Provide a way to skip validations for models
- A type without sensitive types derived from an entity type will now be registered as a
  detached entity
- Fix model type re-registering bug

# [0.0.115] - 2025-05-01

- Make sure Authenticator#authenticate hits #applicable?

# [0.0.114] - 2025-05-01

- Support choosing among multiple processors
- Make Authenticator a Processor
- Give a way for Processor::Selection to give nil when nothing matches

# [0.0.113] - 2025-04-25

- If an inputs transformer fails give relevant error/outcome not an unknown error

# [0.0.112] - 2025-04-25

- Fix bugs preventing generating manifest for connector with mutator instances instead of classes

# [0.0.111] - 2025-04-25

- Fix bug in DomainMapper.depends_on
- Allow mutator instances to be used by connectors not just classes
- Some WeakObjectSet tweaks

# [0.0.110] - 2025-04-23

- Automatically load associations needed for delegated attributes for
  result of commands exposed via command connectors

# [0.0.109] - 2025-04-22

- Support CommandConnector transformers that don't take declaration_data

# [0.0.108] - 2025-04-22

- Fix bug in CommandConnector::NotFoundError constructor

# [0.0.107] - 2025-04-22

- Make sure various Foobara::Error subclasses have consistent interfaces

# [0.0.106] - 2025-04-20

- Fix authenticator explanation that was coupled to pry

# [0.0.105] - 2025-04-20

- Support registering allowed_rule and authenticator on connectors and using them by symbol
- Automatically set requires_authentication if there's an authenticator+allowed_rule for convenience.

# [0.0.104] - 2025-04-17

- Fix manifest bug when command has no possible errors

# [0.0.103] - 2025-04-17

- Fix bugs in complicated entity query calls involving mixtures of models/records/primary keys/attributes
- Fix bugs re: .construct_associations/_deep_associations resulting in terribad performance in some projects
- Allow lambdas to be used as allowed rules
- Improve .delegate_attribute interface

# [0.0.102] - 2025-04-13

- Extract ThreadParent to its own repository/gem

# [0.0.101] - 2025-04-12

- Add Entity#update

# [0.0.100] - 2025-04-11

- Restore missing Response#error

# [0.0.99] - 2025-04-11

- Just testing publishing gem to rubygems with new bundler to see if it resolves issue

# [0.0.98] - 2025-04-10

- Make atomic serializer dig into first entity instead of staying at the top
- Add Request#response

# [0.0.96] - 2025-04-08

- Do not attempt to remove sensitive types from non-model extension declarations

# [0.0.95] - 2025-04-07

- Split up #run and #build_request_and_command in CommandConnector to help subclasses

# [0.0.94] - 2025-04-07

- Support capture_unknown_errors at the command connector level

# [0.0.93] - 2025-04-06

- Add delegated attributes to models
- Add private attributes to models
- Pass manifest construction context through thread_parent instead of passing it everywhere
- Various namespace lookup bugfixes
- Various bugfixes for .find_all/many type of methods in both Model and crud drivers

# [0.0.92] - 2025-04-01

- Improve error call stacks in calls like #run!
- Fix bug preventing first call to CommandConnector#foobara_manifest from returning all its domains

# [0.0.91] - 2025-03-31

- Fix bug that was including removed types in command manifest's inputs_types_depended_on
- Hoist authentication check up into command connector further from transformed command

# [0.0.90] - 2025-03-29

- Implement request mutator concept

# [0.0.89] - 2025-03-29

- Make attributes transformers work with either a from type or a to type

# [0.0.88] - 2025-03-28

- Implement response mutator concept
- Break up #request_to_response for easier overriding/extension
- Add AttributesTransformers::Reject
- Fix problem causing downcase/regex processors to explode on allow_nil types

# [0.0.87] - 2025-03-26

- TypedTransformer refactor to reduce confusion and bugs

# [0.0.86] - 2025-03-23

- Add an AttributesTransformer.only method to quickly get a TypedTransformer (helpful with inputs_transformers)

# [0.0.85] - 2025-03-22

- Add Manifest::TypeDeclaration#sensitive?

# [0.0.84] - 2025-03-22

- Remove sensitive values from command connector results
- Allow creating models in two different namespace trees and use this is the command connector
- Use real domains/orgs in command connectors, eliminating ExposedDomain/Org concept
- Allow Datetime to be cast from a float

# [0.0.82] - 2025-03-21

- Fix bug incorrectly creating model classes in Foobara::GlobalDomain module

# [0.0.81] - 2025-03-21

- No longer automatically creates Foobara::Model classes when creating a foobara model type via type declaration

# [0.0.80] - 2025-03-19

- Fix bug preventing combining array type sugar with sensitive flag in type declarations

# [0.0.79] - 2025-03-19

- Make foobara manifest output more deterministic (alphabetize required fields array)
- Add sensitive/sensitive_exposed type declaration flags
- Add sensitive-type removing feature and default to removing all sensitive (but not sensitive_exposed types)
  from the command connector manifest

# [0.0.78] - 2025-03-17

- Include types that possible errors depend on in TransformedCommand#types_depdended_on

# [0.0.77] - 2025-03-17

- Patch up command connector manifest errors to have their domain be their parent if they're scoped
  to a command that wasn't connected

# [0.0.76] - 2025-03-17

- Add ErrorCollection#clear

# [0.0.75] - 2025-03-15

- Maybe a bad idea, but... add some convenience behavior to casting attributes to records:
  build the record if it has an id that exists, otherwise create it
- When serializing unloaded records, load them instead of raising an error

# [0.0.74] - 2025-03-15

- fix bug where a command connector won't expose the non-global domain of a type if the command it depends on
  is in the global domain

# [0.0.73] - 2025-03-11

- Fix bug preventing false from being used as a default in the Attributes::Dsl

# [0.0.72] - 2025-03-07

- Fix bug in find_many_by when there are required attributes not present in the filter

# [0.0.71] - 2025-03-06

- Make require_primary_key: the default in AttributesHelpers

# [0.0.70] - 2025-03-06

- Make sure Foobara::Command.depends_on is inherited

## [0.0.69] - 2025-03-03

- Allow StateMachine to use an attribute on another object as its current state for convenience

## [0.0.68] - 2025-02-28

- Make use of LruCache for performance boost when converting type declarations to types

## [0.0.67] - 2025-02-26

- Convert / to _ when building constant names in Enumerated::Values

## [0.0.66] - 2025-02-26

- Make sure methods like Command::Manifest#inputs_types_depended_on return [] instead of nil when missing

## [0.0.65] - 2025-02-26

- Fix a problem when looking up domain mappers with a symbol value that doesn't represent a type

## [0.0.64] - 2025-02-25

- Fix bug where DomainMappers created after commands have ran wouldn't be detected
- Expose Enumerated::Values#value?
- Allow passing a hash to DomainMapper#new

## [0.0.63] - 2025-02-25

- Allow creating an Enumerated from a list of value strings that contain colons

## [0.0.62] - 2025-02-21

- Add Manifest::Type#to_type_declaration_from_declaration_data

## [0.0.61] - 2025-02-21

- Add Manifest::Type#custom?

## [0.0.60] - 2025-02-21

- Now including domain mappers in the .depends_on call is optional. If you include any of them, you must include all
  of them. Otherwise, you can include none of them and then no verification of them will be performed.
- Introduce a ranking/scoring system of domain mapper matches to help with certain ambiguous situations

## [0.0.59] - 2025-02-20

- DomainMapper no longer inherits from Command. Instead, both include CommandPatternImplementation mixin

## [0.0.57] - 2025-02-18

- Add Enumerated.make_module helper

## [0.0.56] - 2025-02-16

- Bump Ruby to 3.4.2
- Add an ignore_unexpected_attributes option to Model#initialize

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

- Do not fail :one_of if it is nil and :allow_nil

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
