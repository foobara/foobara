require "foobara/type_declarations/handlers/registered_type_declaration/to_type_transformer"
require "foobara/type_declarations/handlers/extend_associative_array_type_declaration"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredTypeDeclaration < RegisteredTypeDeclaration
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ToTypeTransformer < RegisteredTypeDeclaration::ToTypeTransformer
          def transform(strict_type_declaration)
            # TODO: maybe cache this stuff??
            base_type = super

            casters = base_type.casters.map { |caster| caster.class.new(strict_type_declaration) }
            transformers = base_type.transformers.dup
            validators = base_type.validators.dup
            element_processors = base_type.element_processors.dup

            additional_processors_to_apply = strict_type_declaration.except(*non_processor_keys)

            # TODO: validate the name
            additional_processors_to_apply.each_pair do |processor_symbol, declaration_data|
              processor_class = base_type.find_supported_processor_class(processor_symbol)

              processor = processor_class.new(declaration_data)

              case processor
              when Value::Validator
                validators << processor
              when Value::Transformer
                transformers << processor
              when Types::ElementProcessor
                element_processors ||= []
                element_processors << processor
              else
                # TODO: add validator that these are all fine so we don't have to bother here...
                # :nocov:
                raise "Not sure where to put #{processor}"
                # :nocov:
              end
            end

            Types::Type.new(
              strict_type_declaration,
              base_type:,
              casters:,
              transformers:,
              validators:,
              element_processors:,
              # TODO: can't we just set this to [] here??
              target_classes: target_classes(strict_type_declaration),
              name: type_name(strict_type_declaration)
            )
          end

          # TODO: test that registering a custom type sets its name
          def type_name(strict_type_declaration)
            "Anonymous #{strict_type_declaration[:type]} extension"
          end

          def non_processor_keys
            [:type]
          end
        end
      end
    end
  end
end
