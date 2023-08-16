require "foobara/type_declarations/type_declaration_handler/registered_type_declaration_handler/to_type_transformer"
require "foobara/type_declarations/type_declaration_handler/extend_associative_array_type_declaration_handler"

module Foobara
  module TypeDeclarations
    class TypeDeclarationHandler < Value::Processor::Pipeline
      class ExtendRegisteredTypeDeclarationHandler < RegisteredTypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ToTypeTransformer < RegisteredTypeDeclarationHandler::ToTypeTransformer
          def transform(strict_type_declaration)
            # TODO: maybe cache this stuff??
            base_type = super

            casters = base_type.casters.dup
            transformers = base_type.transformers.dup
            validators = base_type.validators.dup
            element_processors = base_type.element_processors.dup

            additional_processors_to_apply = strict_type_declaration.except(:type)

            # TODO: add validator that these are all fine so we don't have to bother here...
            additional_processors_to_apply.each_pair do |processor_symbol, declaration_data|
              processor_class = base_type.find_supported_processor_class(processor_symbol)
              processor = processor_class.new(
                declaration_data,
                type_registry:,
                type_declaration_handler_registry:
              )

              case processor
              when Value::Validator
                validators << processor
              when Value::Transformer
                transformers << processor
              when Types::ElementProcessor
                element_processors << processor
              else
                raise "Not sure where to put #{processor}"
              end
            end

            Types::Type.new(
              strict_type_declaration,
              base_type:,
              casters:,
              transformers:,
              validators:,
              element_processors:
            )
          end
        end
      end
    end
  end
end
