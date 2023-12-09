module Foobara
  Util.require_project_file("builtin_types", "duck")
  Util.require_project_file("builtin_types", "atomic_duck")
  Util.require_project_file("builtin_types", "duckture")

  module BuiltinTypes
    class << self
      foobara_delegate :global_registry, to: Types
      foobara_delegate :[], :[]=, :registered?, :root_type, :root_type=, to: :global_registry
      foobara_delegate :global_type_declaration_handler_registry, to: TypeDeclarations

      def build_and_register!(type_symbol, base_type, target_classes = const_get("::#{Util.classify(type_symbol)}"))
        type = build_from_modules_and_install_type_declaration_extensions!(type_symbol, target_classes, base_type)

        global_registry.register(type_symbol, type)

        unless global_registry.root_type
          global_registry.root_type = type
        end

        Foobara::Namespace::NamespaceHelpers.foobara_namespace!(type)
        type.scoped_path = [type_symbol.to_s]
        type.foobara_parent_namespace ||= Foobara
        type.foobara_parent_namespace.foobara_register(type)

        type.supported_processor_classes.each_value do |processor_class|
          if !processor_class.scoped_path_set? || processor_class.scoped_path_autoset?
            # TODO: Do we actually need this?
            processor_class.scoped_path = [processor_class.symbol]
          end
          processor_class.foobara_parent_namespace = type
          type.foobara_register(processor_class)
        end

        type
      end

      def build_from_modules_and_install_type_declaration_extensions!(type_symbol, target_classes, base_type)
        desugarizer = TypeDeclarations::Handlers::RegisteredTypeDeclaration::SymbolDesugarizer
        declaration_data = desugarizer.instance.transform(type_symbol)

        module_symbol = Util.classify(type_symbol).to_sym

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
          casters: casters.nil? || casters.empty? ? base_type&.casters.dup || [] : casters,
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
  end
end
