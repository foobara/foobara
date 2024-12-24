module Foobara
  Foobara.require_project_file("builtin_types", "duck")
  Foobara.require_project_file("builtin_types", "atomic_duck")
  Foobara.require_project_file("builtin_types", "duckture")

  module BuiltinTypes
    class << self
      foobara_delegate :global_type_declaration_handler_registry, to: TypeDeclarations

      # TODO: break this up
      # TODO: much of this behavior is helpful to non-builtin types as well.
      def build_and_register!(
        type_symbol,
        base_type,
        target_classes = const_get("::#{Util.classify(type_symbol)}"),
        description: "Built-in #{type_symbol} type"
      )
        declaration_data = { type: type_symbol.to_sym }

        module_symbol = Util.classify(type_symbol).to_sym

        builtin_type_module = const_get(module_symbol, false)

        processor_classes_requiring_type = []

        casters_module = Util.constant_value(builtin_type_module, :Casters)
        caster_classes = if casters_module
                           Util.constant_values(casters_module, extends: Value::Processor)
                         end
        casters = []
        caster_classes&.each do |caster_class|
          if caster_class.respond_to?(:requires_type?) && caster_class.requires_type?
            processor_classes_requiring_type << caster_class
          else
            casters << caster_class.new_with_agnostic_args(parent_declaration_data: declaration_data)
          end
        end

        transformers_module = Util.constant_value(builtin_type_module, :Transformers)
        transformer_classes = if transformers_module
                                Util.constant_values(transformers_module, extends: Value::Processor)
                              end
        transformers = []
        transformer_classes&.each do |transformer_class|
          if transformer_class.respond_to?(:requires_type?) && transformer_class.requires_type?
            # :nocov:
            processor_classes_requiring_type << transformer_class
            # :nocov:
          else
            transformers << transformer_class.new_with_agnostic_args(parent_declaration_data: declaration_data)
          end
        end

        validators_module = Util.constant_value(builtin_type_module, :Validators)
        validator_classes = if validators_module
                              Util.constant_values(validators_module, extends: Value::Processor)
                            end
        validators = []
        validator_classes&.each do |validator_class|
          if validator_class.respond_to?(:requires_type?) && validator_class.requires_type?
            # :nocov:
            processor_classes_requiring_type << validator_class
            # :nocov:
          else
            validators << validator_class.new_with_agnostic_args(parent_declaration_data: declaration_data)
          end
        end

        type = Foobara::Types::Type.new(
          declaration_data,
          base_type:,
          name: type_symbol,
          casters:,
          transformers:,
          validators:,
          # TODO: this is for controlling casting or not casting but could give the wrong information from a
          # reflection point of view...
          target_classes:,
          description:,
          processor_classes_requiring_type:
        )

        add_builtin_type(type)

        # TODO: is this necessary?
        Foobara::Namespace::NamespaceHelpers.foobara_namespace!(type)

        # TODO: really need to encapsulate this somehow...
        type.type_symbol = type_symbol
        type.foobara_parent_namespace ||= GlobalDomain
        type.foobara_parent_namespace.foobara_register(type)

        supported_casters_module = Util.constant_value(builtin_type_module, :SupportedCasters)
        supported_caster_classes = if supported_casters_module
                                     Util.constant_values(supported_casters_module, extends: Value::Processor)
                                   end
        supported_transformers_module = Util.constant_value(builtin_type_module, :SupportedTransformers)
        supported_transformer_classes = if supported_transformers_module
                                          Util.constant_values(supported_transformers_module, extends: Value::Processor)
                                        end
        supported_validators_module = Util.constant_value(builtin_type_module, :SupportedValidators)
        supported_validator_classes = if supported_validators_module
                                        Util.constant_values(supported_validators_module, extends: Value::Processor)
                                      end
        supported_processors_module = Util.constant_value(builtin_type_module, :SupportedProcessors)
        supported_processor_classes = if supported_processors_module
                                        Util.constant_values(supported_processors_module, extends: Value::Processor)
                                      end

        processor_classes = [*transformers, *validators].map(&:class)

        [
          *supported_caster_classes,
          *supported_transformer_classes,
          *supported_validator_classes,
          *supported_processor_classes
        ].each do |processor_class|
          type.register_supported_processor_class(processor_class)
          processor_classes << processor_class
        end

        processor_classes.each do |processor_class|
          install_type_declaration_extensions_for(processor_class)
        end

        [
          [casters_module, caster_classes, casters],
          [transformers_module, transformer_classes, transformers],
          [validators_module, validator_classes, validators],
          [supported_casters_module, supported_caster_classes],
          [supported_processors_module, supported_processor_classes],
          [supported_transformers_module, supported_transformer_classes],
          [supported_validators_module, supported_validator_classes]
        ].each do |(mod, klasses, instances)|
          next unless mod

          prefix = Util.non_full_name(mod)

          [*klasses, *instances].each do |scoped|
            if !scoped.scoped_path_set? || scoped.scoped_path_autoset?
              # TODO: Do we actually need this?
              short_name = Util.non_full_name(scoped)
              short_name = Util.underscore(short_name) unless scoped.is_a?(::Class)

              scoped.scoped_path = [prefix, short_name]
            end

            parent = scoped.scoped_namespace

            if parent.nil? || parent == Foobara || parent == Namespace.global || parent == GlobalDomain
              scoped.foobara_parent_namespace = type
              type.foobara_register(scoped)
            end
          end
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
