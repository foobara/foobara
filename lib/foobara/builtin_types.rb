Foobara::Util.require_directory("#{__dir__}/builtin_types")

module Foobara
  module BuiltinTypes
    class << self
      def global_registry
        @global_registry ||= Types::Registry.new
      end

      delegate :[], :[]=, :registered?, :root_type, :root_type=, to: :global_registry

      def build_and_register_all_builtins!
        duck = build_and_register_from_modules(:duck)

        global_registry.root_type = duck

        atomic_duck = build_and_register_from_modules(:atomic_duck)

        number = build_and_register_from_modules(:number, atomic_duck)
        integer = build_and_register_from_modules(:integer, number)
        # build_and_register_from_modules(:big_integer, integer)
        # float = build_and_register_from_modules(:float, number)
        # build_and_register_from_modules(:big_decimal, float)
        # string = build_and_register_from_modules(:string, atomic_duck)
        # build_and_register_from_modules(:datetime, atomic_duck)
        # build_and_register_from_modules(:date, atomic_duck)
        # build_and_register_from_modules(:boolean, atomic_duck)

        # email = build_and_register_from_modules(:email, string)
        # phone_number = build_and_register_from_modules(:phone_number, string)

        duckture = build_and_register_from_modules(:duckture)

        array = build_and_register_from_modules(:array, duckture)
        # tuple = build_and_register_from_modules(:tuple, array)
        associative_array = build_and_register_from_modules(:associative_array, array)
        attributes = build_and_register_from_modules(:attributes, associative_array)
        # model = build_and_register_from_modules(:model, attributes)
        # entity = build_and_register_from_modules(:entity, model)

        # address = build_and_register_from_modules(:address, model)
        # us_address = build_and_register_from_modules(:us_address, model)
      end

      def build_and_register_from_modules(type_symbol, base_type = root_type)
        type = build_from_modules(type_symbol, base_type)

        global_registry.register(type_symbol, type)

        type
      end

      def build_from_modules(type_symbol, base_type = root_type)
        module_symbol = type_symbol.to_s.camelize.to_sym

        builtin_type_module = const_get(module_symbol, false)

        load_processors_classes = ->(module_name, extends = Class) {
          mod = Util.constant_value(builtin_type_module, module_name)

          mod ? Util.constant_values(mod, extends:) : []
        }

        load_processors = ->(symbol, module_name: "#{symbol}s", extends: Value.const_get(symbol)) {
          load_processors_classes.call(module_name, extends).map(&:instance)
        }

        desugarizer = TypeDeclarations::TypeDeclarationHandler::RegisteredTypeDeclarationHandler::SymbolDesugarizer
        declaration_data = desugarizer.instance.transform(type_symbol)

        type = Foobara::Types::Type.new(
          declaration_data,
          base_type:,
          casters: load_processors.call(:Caster),
          transformers: load_processors.call(:Transformer),
          validators: load_processors.call(:Validator)
        )

        # what about desugarizers and schema validators?? I guess those live with the TypeDeclaration instead?
        %i[SupportedTransformer SupportedValidator SupportedProcessor].each do |module_name|
          load_processors_classes.call(module_name, Value::Processor).each do |processor_class|
            type.register_supported_processor_class(processor_class)
          end
        end

        type
      end
    end

    build_and_register_all_builtins!
  end
end
