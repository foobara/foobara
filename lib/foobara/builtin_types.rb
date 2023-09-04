Foobara::Util.require_directory("#{__dir__}/builtin_types")

module Foobara
  module BuiltinTypes
    class << self
      delegate :global_registry, to: Types
      delegate :[], :[]=, :registered?, :root_type, :root_type=, to: :global_registry
      delegate :global_type_declaration_handler_registry, to: TypeDeclarations

      def build_and_register_all_builtins_and_install_type_declaration_extensions!
        build_and_register!(:duck)
        atomic_duck = build_and_register!(:atomic_duck)
        build_and_register!(:symbol, atomic_duck)
        number = build_and_register!(:number, atomic_duck)
        build_and_register!(:integer, number)
        # float = build_and_register!(:float, number)
        # build_and_register!(:big_decimal, float)
        string = build_and_register!(:string, atomic_duck)
        # build_and_register!(:datetime, atomic_duck)
        # build_and_register!(:date, atomic_duck)
        build_and_register!(:boolean, atomic_duck)
        build_and_register!(:email, string)
        # phone_number = build_and_register!(:phone_number, string)
        duckture = build_and_register!(:duckture)
        build_and_register!(:array, duckture)
        # tuple = build_and_register!(:tuple, array)
        associative_array = build_and_register!(:associative_array, duckture)
        build_and_register!(:attributes, associative_array)
        # model = build_and_register!(:model, attributes)
        # entity = build_and_register!(:entity, model)
        # address = build_and_register!(:address, model)
        # us_address = build_and_register!(:us_address, model)
      end

      def build_and_register!(type_symbol, base_type = root_type)
        type = build_from_modules_and_install_type_declaration_extensions!(type_symbol, base_type)

        global_registry.register(type_symbol, type)

        if global_registry.root_type.blank?
          global_registry.root_type = type
        end

        type
      end

      def build_from_modules_and_install_type_declaration_extensions!(type_symbol, base_type = root_type)
        module_symbol = type_symbol.to_s.camelize.to_sym

        builtin_type_module = const_get(module_symbol, false)

        load_processors_classes = ->(module_name, extends = Class) {
          mod = Util.constant_value(builtin_type_module, module_name)

          mod ? Util.constant_values(mod, extends:) : []
        }

        load_processors = ->(symbol, module_name: "#{symbol}s", extends: Value.const_get(symbol)) {
          load_processors_classes.call(module_name, extends).map(&:instance)
        }

        casters = load_processors.call(:Caster)
        transformers = load_processors.call(:Transformer)
        validators = load_processors.call(:Validator)

        desugarizer = TypeDeclarations::Handlers::RegisteredTypeDeclaration::SymbolDesugarizer
        declaration_data = desugarizer.instance.transform(type_symbol)

        type = Foobara::Types::Type.new(
          declaration_data,
          base_type:,
          name: type_symbol,
          casters: casters.presence || base_type.casters.dup,
          transformers:,
          validators:
        )

        processor_classes = [*transformers, *validators].map(&:class)

        %i[SupportedTransformers SupportedValidators SupportedProcessors].each do |module_name|
          load_processors_classes.call(module_name, Value::Processor).each do |processor_class|
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
          handler_name = handler_module.name.demodulize
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
