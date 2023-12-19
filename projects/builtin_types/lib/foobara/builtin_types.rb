require "date"
require "time"
require "bigdecimal"

module Foobara
  module BuiltinTypes
    class << self
      def builtin_types
        @builtin_types ||= Set.new
      end

      def install!
        duck = build_and_register!(:duck, nil, ::Object)
        builtin_types << duck
        # TODO: should we ban ::Object that are ::Enumerable from atomic_duck?
        atomic_duck = build_and_register!(:atomic_duck, duck, ::Object)
        builtin_types << atomic_duck
        builtin_types << build_and_register!(:symbol, atomic_duck)
        # TODO: wtf why pass ::Object? It's to avoid casting? Do we need a way to flag abstract types?
        number = build_and_register!(:number, atomic_duck, ::Object)
        builtin_types << number
        builtin_types << build_and_register!(:integer, number)
        builtin_types << build_and_register!(:float, number)
        builtin_types << build_and_register!(:big_decimal, number)
        # Let's skip these for now since they rarely come up in business contexts and both could be
        # represented by a tuple of numbers.
        # build_and_register!(:rational, number)
        # build_and_register!(:complex, number)
        string = build_and_register!(:string, atomic_duck)
        builtin_types << string
        builtin_types << build_and_register!(:date, atomic_duck)
        builtin_types << build_and_register!(:datetime, atomic_duck, ::Time)
        builtin_types << build_and_register!(:boolean, atomic_duck, [::TrueClass, ::FalseClass])
        builtin_types << build_and_register!(:email, string, ::String)
        # TODO: not urgent and derisked already via :email
        # phone_number = build_and_register!(:phone_number, string)
        # TODO: wtf
        duckture = build_and_register!(:duckture, duck, ::Object)
        builtin_types << duckture
        array = build_and_register!(:array, duckture)
        builtin_types << array
        builtin_types << build_and_register!(:tuple, array, ::Array)
        associative_array = build_and_register!(:associative_array, duckture, ::Hash)
        builtin_types << associative_array
        # TODO: uh oh... we do some translations in the casting here...
        builtin_types << build_and_register!(:attributes, associative_array, nil)
      end

      def reset_all
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
