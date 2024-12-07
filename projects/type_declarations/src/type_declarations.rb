module Foobara
  require_project_file("type_declarations", "type_builder")
  require_project_file("type_declarations", "error_extension")

  module TypeDeclarations
    module Mode
      STRICT = :strict
      STRICT_STRINGIFIED = :strict_stringified
    end

    class << self
      def global_type_declaration_handler_registry
        GlobalDomain.foobara_type_builder.type_declaration_handler_registry
      end

      def register_type_declaration(type_declaration_handler)
        global_type_declaration_handler_registry.register(type_declaration_handler)
      end

      def strict(&)
        using_mode(Mode::STRICT, &)
      end

      def strict_stringified(&)
        using_mode(Mode::STRICT_STRINGIFIED, &)
      end

      def using_mode(new_mode)
        old_mode = Thread.foobara_var_get(:foobara_type_declarations_mode)
        begin
          Thread.foobara_var_set(:foobara_type_declarations_mode, new_mode)
          yield
        ensure
          Thread.foobara_var_set(:foobara_type_declarations_mode, old_mode)
        end
      end

      def strict?
        Thread.foobara_var_get(:foobara_type_declarations_mode) == Mode::STRICT
      end

      def strict_stringified?
        Thread.foobara_var_get(:foobara_type_declarations_mode) == Mode::STRICT_STRINGIFIED
      end

      # TODO: we should desugarize these but can't because of a bug where desugarizing entities results in creating the
      # entity class in memory, whoops.
      def declarations_equal?(declaration1, declaration2)
        declaration1 = declaration1.reject { |(k, _v)| k.to_s.start_with?("_") }.to_h
        declaration2 = declaration2.reject { |(k, _v)| k.to_s.start_with?("_") }.to_h

        declaration1 == declaration2
      end
    end
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
