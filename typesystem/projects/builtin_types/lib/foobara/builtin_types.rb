require "date"
require "time"
require "bigdecimal"

module Foobara
  # TODO: rename this to PrimitiveTypes and deprecate the name BuiltinTypes
  module BuiltinTypes
    class << self
      def builtin_types
        @builtin_types ||= Set.new
      end

      def add_builtin_type(type)
        @builtin_references = nil
        builtin_types << type
        type.is_builtin = true
      end

      def builtin_references
        @builtin_references ||= builtin_types.to_set(&:foobara_manifest_reference)
      end

      def builtin?(type)
        builtin_types.include?(type)
      end

      def builtin_reference?(reference)
        builtin_references.include?(reference)
      end

      def [](symbol)
        builtin_types.find do |type|
          type.type_symbol == symbol
        end
      end

      def install!
        duck = build_and_register!(:duck, nil, ::Object)
        # TODO: should we ban ::Object that are ::Enumerable from atomic_duck?
        atomic_duck = build_and_register!(:atomic_duck, duck, ::Object)
        build_and_register!(:symbol, atomic_duck)
        # TODO: wtf why pass ::Object? It's to avoid casting? Do we need a way to flag abstract types?
        number = build_and_register!(:number, atomic_duck, ::Object)
        build_and_register!(:integer, number)
        build_and_register!(:float, number)
        build_and_register!(:big_decimal, number)
        # Let's skip these for now since they rarely come up in business contexts and both could be
        # represented by a tuple of numbers.
        # build_and_register!(:rational, number)
        # build_and_register!(:complex, number)
        string = build_and_register!(:string, atomic_duck)
        build_and_register!(:date, atomic_duck)
        build_and_register!(:datetime, atomic_duck, ::Time)
        build_and_register!(:boolean, atomic_duck, [::TrueClass, ::FalseClass])
        build_and_register!(:email, string, ::String)
        # TODO: not urgent and derisked already via :email
        # phone_number = build_and_register!(:phone_number, string)
        # TODO: wtf
        duckture = build_and_register!(:duckture, duck, ::Object)
        array = build_and_register!(:array, duckture)
        build_and_register!(:tuple, array, ::Array)
        associative_array = build_and_register!(:associative_array, duckture, ::Hash)
        # TODO: uh oh... we do some translations in the casting here...
        build_and_register!(:attributes, associative_array, nil)
      end

      def reset_all
        Foobara.raise_if_production!("reset_all")

        builtin_types.each do |builtin_type|
          builtin_type.foobara_each do |scoped|
            if scoped.scoped_namespace == builtin_type
              scoped.scoped_namespace = nil
            end
          end
        end

        builtin_types.clear

        install!
      end
    end
  end
end
