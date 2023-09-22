require "date"
require "time"
require "bigdecimal"

Foobara.load_project(__dir__)

module Foobara
  module BuiltinTypes
    class << self
      def build_and_register_all_builtins_and_install_type_declaration_extensions!
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
        # What does a model have that :attributes doesnt have?
        #   name
        #   a target class (can default to a dynamically created Foobara::Model ??)
        #     #valid?
        #     #attributes
        #     readers/writers for all attributes
        # NOTE: A model isn't attributes!!! it has attributes. It is instead an atomic duck.
        # Subtypes should not use ::Hash as the target type. This is a confusing hack.
        model = build_and_register!(:model, atomic_duck, nil)
        build_and_register!(:entity, model, nil)
        # address = build_and_register!(:address, model)
        # us_address = build_and_register!(:us_address, model)
      end
    end

    build_and_register_all_builtins_and_install_type_declaration_extensions!
  end
end
