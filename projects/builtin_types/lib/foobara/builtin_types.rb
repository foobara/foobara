require "date"
require "time"
require "bigdecimal"

Foobara::Util.require_directory("#{__dir__}/../../src")

module Foobara
  module BuiltinTypes
    class << self
      foobara_delegate :global_registry, to: Types
      foobara_delegate :[], :[]=, :registered?, :root_type, :root_type=, to: :global_registry
      foobara_delegate :global_type_declaration_handler_registry, to: TypeDeclarations

      def reset_all
        build_and_register_all_builtins_and_install_type_declaration_extensions!
      end

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

      def build_and_register!(type_symbol, base_type, target_classes = const_get("::#{type_symbol.to_s.camelize}"))
        type = build_from_modules_and_install_type_declaration_extensions!(type_symbol, target_classes, base_type)

        global_registry.register(type_symbol, type)

        if global_registry.root_type.blank?
          global_registry.root_type = type
        end

        type
      end

      def build_from_modules_and_install_type_declaration_extensions!(type_symbol, target_classes, base_type)
        desugarizer = TypeDeclarations::Handlers::RegisteredTypeDeclaration::SymbolDesugarizer
        declaration_data = desugarizer.instance.transform(type_symbol)

        module_symbol = type_symbol.to_s.camelize.to_sym

        builtin_type_module = const_get(module_symbol, false)

        load_processor_classes = ->(module_name) {
          mod = Util.constant_value(builtin_type_module, module_name)

          if mod
            Util.constant_values(mod, extends: Value::Processor)
          else
            []
          end
        }

        load_processors = ->(module_name) {
          load_processor_classes.call(module_name).map do |processor_class|
            processor_class.new_with_agnostic_args(true, declaration_data)
          end
        }

        casters = load_processors.call(:Casters)
        transformers = load_processors.call(:Transformers)
        validators = load_processors.call(:Validators)

        type = Foobara::Types::Type.new(
          declaration_data,
          base_type:,
          name: type_symbol,
          casters: casters.presence || base_type&.casters.dup || [],
          transformers:,
          validators:,
          # TODO: this is for controlling casting or not casting but could give the wrong information from a
          # reflection point of view...
          target_classes:,
          type_registry: Types.global_registry
        )

        processor_classes = [*transformers, *validators].map(&:class)

        %i[SupportedTransformers SupportedValidators SupportedProcessors].each do |module_name|
          load_processor_classes.call(module_name).each do |processor_class|
            type.register_supported_processor_class(processor_class)
            processor_classes << processor_class
          end
        end

        processor_classes.each do |processor_class|
          install_type_declaration_extensions_for(processor_class)
        end

        type
      end

      def install_type_declaration_extensions_for(processor_class)
        extension_module = Util.constant_value(processor_class, :TypeDeclarationExtension)

        return unless extension_module

        Util.constant_values(extension_module, is_a: ::Module).each do |handler_module|
          handler_name = Util.non_full_name(handler_module)
          handler_class_to_extend = TypeDeclarations::Handlers.const_get(handler_name)

          unless handler_class_to_extend
            # :nocov:
            raise "Couldn't find handler class for #{handler_name}"
            # :nocov:
          end

          handler_to_extend = global_type_declaration_handler_registry.type_declaration_handler_for_handler_class(
            handler_class_to_extend
          )

          unless handler_to_extend
            # :nocov:
            raise "Could not find a handler for #{handler_class_to_extend}"
            # :nocov:
          end

          desugarizer_module = Util.constant_value(handler_module, :Desugarizers)

          if desugarizer_module
            desugarizer_classes = Util.constant_values(desugarizer_module, is_a: ::Class)

            desugarizer_classes.each do |desugarizer_class|
              desugarizer = desugarizer_class.instance

              handler_to_extend.desugarizers << desugarizer
            end
          end

          validator_module = Util.constant_value(handler_module, :TypeDeclarationValidators)

          if validator_module
            validator_classes = Util.constant_values(validator_module, is_a: Class)

            validator_classes.each do |validator_class|
              validator = validator_class.instance

              handler_to_extend.type_declaration_validators << validator
            end
          end
        end
      end
    end

    build_and_register_all_builtins_and_install_type_declaration_extensions!
  end
end