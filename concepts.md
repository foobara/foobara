<!-- TOC -->
  * [Type instance](#type-instance)
  * [TypeRegistry](#typeregistry)
  * [type declaration value](#type-declaration-value)
  * [TypeBuilder](#typebuilder)
  * [TypeBuilderRegistry (unclear if needed)](#typebuilderregistry-unclear-if-needed)
  * [ValueProcessor](#valueprocessor)
  * [ValueCaster < ValueProcessor](#valuecaster--valueprocessor)
  * [TypeDeclarationAwareValueProcessor < ValueProcessor](#typedeclarationawarevalueprocessor--valueprocessor)
  * [ValueValidator < TypeDeclarationAwareValueProcessor](#valuevalidator--typedeclarationawarevalueprocessor)
  * [ValueTransformer < TypeDeclarationAwareValueProcessor](#valuetransformer--typedeclarationawarevalueprocessor)
  * [Desugarizer](#desugarizer)
  * [Sugarizer (maybe not worth spending time writing)](#sugarizer-maybe-not-worth-spending-time-writing)
  * [strict type declaration validator](#strict-type-declaration-validator)
<!-- TOC -->

# Concepts

## Type instance

* metaprogramming
    * answers metaprogramming questions about the type
    * (passive) can serve as a base type for another type
    * can give a type declaration value (formal or informal/sugary or strict) for this type
    * can give the list of possible errors that could result from processing a value of this type
      and the types for their context schemas
    * can answer what value processors are supported for values of this type
    * can answer which value processors are automatically applied for values of this type
* value operations
    * can process a value of this type
        * can answer if a value needs to be cast
        * can answer if a value can be cast
        * can cast a value into an value of this type
        * can transform a value of this type
        * can validate a value of this type
* registry operations
    * can register a supported value processor
    * can register a value caster

## TypeRegistry

* Can register a type instance on the registry with a given key.
    * Can register it multiple times with multiple keys.
* Can lookup a type instance on the registry by key.
* TypeRegistry instance can have fallback registry instances. If not finding it
  in this registry, will ask each fallback registry.

## type declaration value

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

## TypeBuilder

* Takes a type declaration value and returns a new type that obeys the rules of the
  type declaration
    * This might require first finding a TypeBuilder instance or class that knows how to properly
      transform this specific type declaration value into a type. So there might be subclasses
      such as TypeBuilder::Attributes and TypeBuilder::Integer

## TypeBuilderRegistry (unclear if needed)

* In the event that we do need to figure out which TypeBuilder is applicable to a given
  sugary type declaration

## ValueProcessor

* Has a call method that receives a value and returns an Outcome
    * Might be a bit more flexible if we pass in an Outcome...
        * For example, then processors know if we're already failing or not...
* Can have an applicable?(value) method
* Answers what errors can be raised
    * Including the type of their context
* Answers type of processor data
* Answers type of value to process

## ValueCaster < ValueProcessor

* gives #cast instead of #transform but same idea, takes value returns value
* like ValueProcessor, never gives errors
* only one value caster per type should be #applicable? for a given value.
    * Therefore doesn't have to play nicely with other Casters, unlike Transformers/Validators

## TypeDeclarationAwareValueProcessor < ValueProcessor

* Can have a type declaration desugarizer
* Can have a type declaration validator

## ValueValidator < TypeDeclarationAwareValueProcessor

* gives #validation_errors that takes value and returns errors
* never gives new value

## ValueTransformer < TypeDeclarationAwareValueProcessor

* gives #transfomer that takes value and returns value
* never gives errors

## Desugarizer

* takes sugary type declaration and returns strict type declaration

## Sugarizer (maybe not worth spending time writing)

* takes strict type declaration and returns sugary type declaration

## strict type declaration validator

* takes strict type declaration, returns errors

# Project structure and dependencies?

* Type depends on... 
  * ValueProcessor/Caster/Transformer/Validator
* ValueProcessor/Caster/Transformer/Validator knows about... 
  * Type (because it has error context type, etc..)
    * So we have a bi-directional dependency there. Therefore either this is a smell or we should package these up together
* The collection of primitive type instances depends on
  * Type
* TypeRegistry depends on
  * Type
* type declaration value depends on nothing (not an instance of any specific class)
* TypeBuilder depends on
  * type declaration value
  * Type
  * ValueProcessor etc
  * TypeRegistry
    * So it can lookup base types, attribute types, etc
* TypeBuilderRegistry depends on
  * TypeRegistry
* Desugarizer/Sugarizer
  * is a type of transformer and therefore might depend on ValueProcessor/etc but not sure
* strict type declaration validator
  * might be a type of ValueValidator but not sure

So possible dependency tree would be...

project A: Type + ValueProcessor and friends
project B: primitive Type classes
project C: TypeRegistry
project D: TypeBuilder, Desugarizer/Sugarizer, strict type declaration validator
project E: TypeBuilderRegistry

B -> A
C -> A
D -> C, A
E -> C

Big design issue... ValueValidator has a desugarizer and strict type declaration validator

We can decouple that but then person writing the ValueValidator has to put the desugarizer and declaration validator elsewhere
instead of grouping them and registering them together. Maybe this is OK? Probably only
foobara engineers would be affected as application/domain engineers would likely make
heavy use of the attributes type for building custom types.

Do we just group all of these into one project except maybe primitive type classes?

Let's go through use-case of making a model with a custom validator...

contrived custom validator:

Must have email or phone number or both...

```ruby
type = type_builder_registry.from(
  extends: :attributes,
  attribute_schemas: {
    first_name: :string,
    last_name: :string,
    phone_number: :string,
    email: :string  
  },
  at_least_one_present: [:phone, :email]
)

class AtLeastOnePresent < ValueValidator
  def attribute_names
    data
  end
  
  def applicable?(_attributes_hash)
    attribute_names.present? 
  end
  
  def call(attributes_hash)
    if attributes_hash.slice(*attribute_names).values.any?
      build_error
    end
  end
  
  def error_message
    "must have at least a phone number or email"
  end
  
  def error_context
    { foo: :bar }
  end
  
  def error_context_type
    type_builder_registry.from(
      :attributes,
      attribute_schemas: {
        foo: :symbol
      }
    )
  end
  
  def error_class
    Error
  end
  
  def error_symbol
    :missing_both_phone_and_email
  end
  
  def validator_data_type
    # TODO: should use enumerated type here??
    type_builder_registry.from(:array, element_type: [:symbol])
  end
  
  # Ohhh we could parameterize this... How would we do that? pass type to constructor?
  def value_type
    type_builder_registry[:attributes]
  end
end
```

So now what? We need
a desugarizer that can set email and phone as optional. We optionally could add a 
strict type declaration validator. no need in this example but we should do it anyways to test 
the use-case

We also need to register these 3 things.

```ruby 
class AtLeastOnePresentValidatorDesugarizer < TypeDeclarationDesugarizer
  def desugarize(type_declaration)
    type_declaration[:optional] ||= []
    
    type_declaration[:optional] += attribute_names    
    
    type_declaration
  end
end

class AtLeastOnePresentValidatorSugarizer < TypeDeclarationSugarizer
  def sugarize(type_declaration)
    type_d eclaration[:optional] ||= []

    type_declaration[:optional] -= attribute_names
    
    type_declaration
  end
end

class AtLeastOnePresentValidatorTypeDeclaration < StrictTypeDeclarationValidator
  def validation_errors(strict_type_declaration)
    if strict_type_declaration[:at_least_one_present].size < 2
      build_error
    end
  end
end
```

TODO: shouldn't use TypeBuilder but rather an instance of type_builder_registry, right?? How do we inject that?? Inheritance? Pass to constructor?
TODO: need a better name for validator data than "data"


how to register stuff??

```ruby
type_registry[:attributes].register_supported_validator(
  AtLeastOnePresentValidator,
  :at_least_one_present,
  type_declaration_validators: [AtLeastOnePresentValidatorTypeDeclaration.new]
  desugarizers: [AtLEastOnePresentValidatorDesugarizer.new],
  sugarizers: [AtLEastOnePresentValidatorSugarizer.new],
)
```

Maybe something that can extract its data from the strict type declaration so that
if there's anything left it's a bug?

Do we really need that level of granularity??

Maybe just couple everything...

Additional thoughts...

* should have simple primitive types (integer, string, etc)
* primitive structured types (array, hash, attributes, tuple)
* a way to support self-referential types
* a way to have unioned types. like... Type[:integer] | TypeBuilder.for([:duck], equals: nil)
  as a way to say something is an integer or nil. Although specifically for htis we should probably
  just support it first class since it would by far be the most common union type. Therefore,
  union types really might not be that useful in practice, frankly.

Should we have a way to run ad-hoc validators?

So like... some_type.validate(value, max: 5) ?


So what are the current concepts and how do they map to new concepts?


New concepts...

* Type instance
* TypeRegistry
* type declaration value
* TypeBuilder
* TypeBuilderRegistry (unclear if needed)
* ValueProcessor
* ValueCaster < ValueProcessor
* TypeDeclarationAwareValueProcessor < ValueProcessor
* ValueValidator < TypeDeclarationAwareValueProcessor
* ValueTransformer < TypeDeclarationAwareValueProcessor
* Desugarizer
* Sugarizer (maybe not worth spending time writing)
* strict type declaration validator

Maybe introduce a TypeDeclaration class to wrap the type declaration values??

Old concepts...

* Type instance
  * high-level value processor and really nothing else! [Type]
* Schema class
  * holds schema registry
  * answers if it can handle a sugary schema type [TypeBuilder, or, maybe when registering?]
  * Has a subclass for the "type" [Type]
  * houses supported value processors registry [Type]
* Schema instance
  * Desugarizes [TypeDeclaration]
  * validates strict schema hash [TypeDeclaration]
  * TypeBuilder: builds types [TypeBuilder]
* ValueValidator/Processor/Transformer/Caster
  * same
* strict schema "hash"
  * strict type declaration value
* sugary schema "hash"
  * sugary type declaration
* schema registry
  * TypeBuilderRegistry?? [TypeBuilderRegistry? TypeRegistry? unclear which]


TODO: decompose Schema to eliminate subclasses and then relocate behaviors until Schema is gone
TODO: Also, move everything out of Model project for now since no actual direct modeling support has begun there yet

* What is the difference between Type and TypeDeclaration?
  * Similarities...
    * Both take a value, "process" it, and return a transformfed value or errors (an outcome)
      * Or at least it would be reasonable to view them both this way.
      * So that means both seem to implement ValueProcessor interface?
      * One potential difference: we never want to proceed with a bad schema.
      * How does process work for each?
        * Type
          * Takes value
          * Casts value that can be processed by other processors
          * Transforms the value (for example, attributes type adds defaults)
          * Validates the value (for example, attributes makes sure required attributes are all present)
        * TypeDeclaration
          * Takes (potentially sugary) type declaration value
          * Desugarizes it into strict type declaration value
            * very similar to casting/transforming
          * Validates the the type declaration value
    * Both have use cases where we have a collection of instances of each and we need to
      find the appropriate one to use for processing
* This seems to imply that TypeDeclaration is a subclass of Type and that TypeDeclarationRegistry
  if it exists would be a subclass of TypeRegistry

TODO: so is it possible to move forward by renaming Schema to TypeDeclaration and having it inherit from Type??
