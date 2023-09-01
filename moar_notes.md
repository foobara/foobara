Attempt to determine definitions yet again...

# current concepts

* sugary schema "hash"
  * Meant for human reading/writing to express and communicate information about data
* strict schema "hash"
  * Meant for automated use/metaprogramming
* "Schema" subclass
  * Indicates whether it is meant to handle a given sugary schema (.can_handle?)
  * Manages registering and inspecting value validators and value transformers meant for use with instances of this "Schema"
* "Schema" instance 
  * Knows how to interpret a given instance of a sugary schema 
  * Can give a strict schema 
  * Can convert this sugary schema into a "Type"
* "Type"
  * Knows how to "process" a data value which means casting, transforming, and validating that value into the expected result.
* "Value Processor"
  * Superclass of Value Validator and Value Transformer
* Value Validator
  * Takes a value and returns validation errors
  * Gives information about the error type that could be returned
    * error symbol
    * error context schema
  * Gives information about the "validator data" it accepts
  * Can provide a desugarizer
  * Can provide a strict schema "hash" validator
* Value Transformer
    * Takes a value and returns a value
    * Gives information about the error type that could be returned
        * error symbol
        * error context schema
    * Gives information about the "transformer data" it accepts
    * Can provide a desugarizer
    * Can provide a strict schema "hash" validator
    * These run before validators
* Value Caster
  * A special type of Value Transformer
    * A key difference is only one applicable caster will be ran whereas all value transformers are ran
    * Another difference is that Casters run before Transformers

# Some noticeable concepts that are not currently first class but probably should be...

* Desugarizer
* strict schema Validator

# Current Challenges

* The names of "Schema" and "Type" are ambiguous and confusing
* Dealing with "Schema" can be confusing in cases where it's ambiguous if we have a Schema class, a Schema instance, or a schema value "hash"
  * In fact, in all of these cases there can be a bit of confusion between class and instance responsibilities
* Currently the single-direction dependency between these has been a bit broken. Before, Schema knew about Type but not the other way around. This has eroded. Unclear what to do about this, if anything.
* "Type" seems to basically process values. However, the class name "Value Processor" already exists and is in use for the base class of Value Validator and Value Transformer

# Epiphanies
* Whoa...
  * Selecting a Schema base class to use for a schema value "hash" is a somewhat similar concept to deciding which Caster to apply to a value
  * Desugarizing a sugary schema "hash" is very similar to applying a Value Transformer
  * Validating a strict schema "hash" is very similar to applying a Value Validator
* Worth an attempt to generalize that concept? Probably worth a try.

## How to carry out these 3 operations? which interfaces?

* Selecting first transformer (Caster or "Schema") to run:
  * What do we want to call this thing??
    * no clue
  * .applicable?
* Value Transformers (Value Transformer or Desugarizer)
  * transform
* Value Validators (Value Validator or Schema Validator)
  * validation_errors

## What to do in "Schema" world?
* What do we call thing that takes a sugary schema value and
  returns a "Schema" class which would be analogous to the thing that takes a value
  and returns a Caster?
  * For the responsibility of finding the thing in question that has a truthy .can_handle?, we can call that
    a Registry
  * But what do we call the thing in question??
    * let's explore...
      * "Schema" class world...
        * Real confusion here between class an instance
          * Perhaps we need yet another class to distinguish?
          * Or maybe we need to eliminate the subclasses so that
            .can_handle? dies?
          * What are the various levels involved here??
            * System programmer wants to: define a new type of type which can be configured (class Complex < Schema... global.register(Complex) for example)
            * Domain programmer wants to define business model
              inventory_complex_schema = register_schema(:inventory_complex, { type: :attributes, schemas: { c: :complex, sku: :string })
            * Domain/Application programmer wants to use domain model to create command
              input_schema(some_ic: :inventory_complex)
            * Application programmer or runtime tooling wants to validate a value
              ic = inventory_complex_schema.process_value!({c: {r: 1, i:2}, sku: "abc123")
        * :integer -> Schema::Integer
          * { :integer, max: 10 } -> Schema::Integer.new
      * Value world
        * "10" -> Casters::Integer::String
          * "10" -> 10
* So maybe we need Desugarizer to implement Value Transformer?
  * Takes sugary schema value and returns strict schema value



# Flows of data through transformers and validators

Given: sugary_schema_hash

validate sugary_schema_hash (this is an over-simplification as what is found here is the pipeline not just errors...)
transform_sugary_schema hash

= strict schema "hash"

validate strict schema "hash"

This can be stored for later


GIVEN unprocessed_value + strict_schema "hash"

validate unprocessed value
transform unprocessed_value (cast + transform)

= processe_value

validate processed_value



so things seem to be monads or have pipelines of validatos and transformers.

other concerns:

how to either store or find the proper strict schema hash when needed?

Three concepts that seem to repeat:

take value return value (transformer)
take value return error array (validator)
map value to pipeline (pipeline returns outcome)

pipeline is an array of validators and transformers. Takes value returns outcome.

pipeline = pipeline_finder(value)
pipeline.call(value) -> outcome

ValidatorChain -> errors[]
TransformerChain -> value
Pipeline -> outcome

PipelineFinder? PipelineSelector? Processor?

value -> value is transformer
value -> [errors] is validator
value -> outcome is processor
value -> processor is processor registry
value -> validator is validator registry
value -> transformer is transformer registry

[transformer] -> transformer is ChainedValidator
[validator] -> validator is ChainedValidator
[processor] -> processor is ChainedProcessor

These should all operate off of ".call"

What about for exposing schema metadata?
How about just a .metadata method?

Foobara::ValueProcessing

Transformer
ChainedTransformer
TransformerRegistry
Validator
ChainedValidator
ValidatorRegistry
Processor
ChainedProcessor
ProcessorRegistry

Action item... make a value_processing project for now
