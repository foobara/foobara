require "active_support/core_ext/object/deep_dup"

Foobara::Util.require_directory("#{__dir__}/type_declarations")

# TODO: extend Error with context_type behavior

module Foobara
  module TypeDeclarations
    class << self
      def global_type_declaration_handler_registry
        Namespace::GLOBAL.type_declaration_handler_registry
      end

      def register_type_declaration(type_declaration_handler)
        global_type_declaration_handler_registry.register(type_declaration_handler)
      end

      def error_context_type_declaration(error_class)
        context_type_declaration = nil

        if error_class.respond_to?(:context_type_declaration)
          context_type_declaration = error_class.context_type_declaration
        else
          # This feels dirty but decouples two projects: Value and Types
          {
            Value::Processor::Casting::CannotCastError => {
              cast_to: :duck,
              value: :duck,
              attribute_name: :symbol
            },
            Value::Processor::Selection::NoApplicableProcessorError => {
              processors: :duck,
              value: :duck
            },
            Value::Processor::Selection::MoreThanOneApplicableProcessorError => {
              processors: :duck,
              applicable_processors: :duck,
              value: :duck
            },
            Value::AttributeError => {
              attribute_name: :symbol,
              value: :duck
            }

          }.each_pair do |klass, type_declaration|
            if klass == error_class || error_class < klass
              context_type_declaration = type_declaration
              break
            end
          end

          unless context_type_declaration
            # :nocov:
            raise "Not sure how to convert #{error_class} into a context type declaration"
            # :nocov:
          end

          context_type_declaration
        end
      end
    end

    register_type_declaration(Handlers::RegisteredTypeDeclaration.new)
    register_type_declaration(Handlers::ExtendRegisteredTypeDeclaration.new)
    register_type_declaration(Handlers::ExtendAttributesTypeDeclaration.new)
  end
end

=begin
how many handlers do we need??


find registered type by symbol

extend registered type (find it by symbol and use it to construct new type with additional processors)

Duck
  AtomicDuck
    Number
      Integer
        BigInteger
      Float
        BigDecimal
    String
      Email
      Phone
    Datetime
    Date
    Boolean
  Duckture
    Array
      Tuple
      AssociativeArray
        Attributes
          Model
            Address
              UsAddress
            Entity

Duck (RegisteredTypeExtensionTypeDeclarationHandler)
  AtomicDuck (N/A)
    Number (N/A)
      Integer (RegisteredTypeExtensionTypeDeclarationHandler)
        BigInteger (RegisteredTypeExtensionTypeDeclarationHandler)
      Float (RegisteredTypeExtensionTypeDeclarationHandler)
        BigDecimal (RegisteredTypeExtensionTypeDeclarationHandler)
    String (RegisteredTypeExtensionTypeDeclarationHandler)
      Email (implement in terms of string extension)
      Phone (implement in terms of string extension)
    Datetime (RegisteredTypeExtensionTypeDeclarationHandler)
    Date (RegisteredTypeExtensionTypeDeclarationHandler)
    Boolean (RegisteredTypeExtensionTypeDeclarationHandler)
  Duckture (N/A)
    Array (hmmmm we need an element processor initialized with the element type...)
      Tuple (hmmmm we need an element processor initialized with the elements type...)
      AssociativeArray (hmmmm we need an element processor initialized with the key type and the value type...)
        Attributes (we need an element processor initialized with the attribute_types)
          Model (same as above but need to add a name attribute...)
            Address (implement in terms of model)
              UsAddress (implement in terms of Address)
            Entity (same as above but with a primary key processor of some sort)


TypeDeclarationHandler
  RegisteredAtomTypeExtensionTypeDeclarationHandler
  RegisteredStructuredTypeExtensionTypeDeclarationHandler
    ExtendArrayTypeDeclarationHandler
    ExtendTupleTypeDeclarationHandler
    ExtendAssociativeArrayTypeDeclaration
    ExtendAttributesTypeDeclaration
    ExtendModelTypeDeclarationHandler
    ExtendEntityTypeDeclarationHandler

I think we need these type declarations but not necessarily Type subclasses for all of these types

Maybe just one Type class??

let's see...

for atom could just not support element_types nor size
for array element_types could just be applied repeating?? Kind of goofy
For tuple element_types could be applied repeating and size validator could be added
for associative array... element_types need to be a hash instead of an array. Is that OK?
  Or could be an array of pairs... like Hash#to_a ? Maybe we just operate off of #each? Seems that will work, wow...
For Attributes same as associative array but with key processor of symbol plus an attributes_processor
For model add a name processor
for entity add a primary key processor of some sort...
=end
