<!-- TOC -->

* [Command](#command)
* [Type < Value::Processor](#type--valueprocessor)
* [type declaration value](#type-declaration-value)
* [Type reference](#type-reference)
* [Domain](#domain)
* [Organization](#organization)
* [Domain mapper](#domain-mapper)
* [Value::Processor](#valueprocessor)
    * [Value::Caster < Value::Processor](#valuecaster--valueprocessor)
    * [Value::Validator < Value::Processor](#valuevalidator--valueprocessor)
    * [Value::Transformer < Value::Processor](#valuetransformer--valueprocessor)
    * [Desugarizer < Value::Transformer](#desugarizer--valuetransformer)
    * [TypeDeclarationValidator < Value::Validator](#typedeclarationvalidator--valuevalidator)
        * [in general:](#in-general)
        * [types and type declarations:](#types-and-type-declarations)

<!-- TOC -->

These are notes about some things conceptual.

# Command

* A command is an encapsulation of a high-level business operation and is intended to be the public
  interface of a system or subsystem.

# Type < Value::Processor

A type is an instance of the Types::Type class.

It (the instance) is a namespace.

It is a Value::Processor

* reflection
    * can give a type declaration value (formal or informal/sugary or strict) for this type
    * can give the list of possible errors that could result from processing a value of this type
      and the types for their context schemas
    * can answer what value processors are supported for values of this type
    * can answer which value processors are automatically applied for values of this type
* can serve as a base type for another type
* can process a value of this type
    * can answer if a value needs to be cast
    * can answer if a value can be cast
    * can cast a value into an value of this type
    * can transform a value of this type
    * can validate a value of this type
* processor registry operations
    * can register a supported value processor
    * can register a value caster

# type declaration value

* Something that defines/declares a type in a declarative fashion.
    * Can have a sugary form for human expression/readability/writability
    * Is easily serializable for cross-system metaprogramming
* example:
  ```ruby
  { 
    foo: :integer,
    bar: [:integer, :optional, :allow_blank, min: 1]
  }
  ```
* In this example, we are using a sugary declaration to specify a new type of
  attributes type that can represent a value like `{ foo: -20, bar: 10 }`

# Type reference

* References a "registered" type. A registered type has a type symbol and belongs to a domain.
* An unresolved type reference doesn't have to be absolute and is looked up in the current
  Foobara namespace.
* A resolved type is absolute.
* A type reference can be used as a type declaration.

# Domain

* A namespace for Commands and Types
* can depend on other domains in a unidirectional way

# Organization

* namespace for collecting domains

# Domain mapper

* Translates models (or types or commands inputs/results) to models (or types or command inputs/results) in
  another domain.

# Value::Processor

* Has a process_value method that receives a value and returns an Outcome
* Can have an applicable?(value) method
* Answers what errors are possible
    * Including the type of their context

## Value::Caster < Value::Processor

* gives #cast instead of #transform but same idea, takes value returns value
* like ValueProcessor, never gives errors
* only one value caster per type should be #applicable? for a given value.
    * Therefore doesn't have to play nicely with other Casters, unlike Transformers/Validators

## Value::Validator < Value::Processor

* gives #validation_errors that takes value and returns errors
* never gives new value

## Value::Transformer < Value::Processor

* gives #transfomer that takes value and returns value
* never gives errors

## Desugarizer < Value::Transformer

* takes sugary type declaration and returns strict type declaration

## TypeDeclarationValidator < Value::Validator

* Validates type declarations

A way to think about the interfaces/concepts involved here, if helpful:

### in general:

* Processor, Multi, Selection, Pipeline: value -> outcome
* Multi < Processor: value -> outcome
* Selection < Multi (chooses 1 processor among many to run): value -> outcome
* Pipeline < Multi (chains a collection of processors together): value -> outcome
* Processor, Multi, Selection, Pipeline: value -> outcome
* Transformer: value -> value
* Validator: value -> error[]

Maybe not helpful, but, you could think of Processor/Multi/Selection/Pipeline as monads
and Validator and Transformer as monads but with convenience methods that make assumptions
about the context (transformer assumes there are no errors and validator assumes
no transformation of the value.)

### types and type declarations:

* TypeDeclarationHandler: type declaration -> Type instance
* TypeDeclarationHandlerRegistry: type declaration -> outcome<TypeDeclarationHandler>
* Desugarizer: type declaration -> strict(er) type declaration
* TypeDeclarationValidator: strict type declaration -> error[]
* Type instance: value -> outcome
* Type casting (is a Value::Pipeline of casters): value -> value
* Caster: value -> value
* Type transformers: value -> value
* Type validators: value -> error[]
* Type processors: value -> outcome
* Supported type processors: value -> outcome
* Supported type transformers: value -> value
* Supported type validators: value -> error[]
