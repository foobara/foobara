Foobara.require_project_file("type_declarations", "handlers/registered_type_declaration/to_type_transformer")
Foobara.require_project_file("type_declarations", "handlers/extend_associative_array_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredTypeDeclaration < RegisteredTypeDeclaration
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ToTypeTransformer < RegisteredTypeDeclaration::ToTypeTransformer
          def dup_processors(processors, parent_declaration_data)
            processors&.map do |processor|
              processor.dup_processor(parent_declaration_data:)
            end
          end

          def transform(strict_type_declaration)
            # TODO: maybe cache this stuff??
            base_type = super

            casters = dup_processors(base_type.casters, strict_type_declaration)
            transformers = dup_processors(base_type.transformers, strict_type_declaration)
            validators = dup_processors(base_type.validators, strict_type_declaration)
            element_processors = dup_processors(base_type.element_processors, strict_type_declaration)

            additional_processors_to_apply = strict_type_declaration.except(*non_processor_keys)

            # TODO: validate the name
            additional_processors_to_apply.each_pair do |processor_symbol, declaration_data|
              processor_class = base_type.find_supported_processor_class(processor_symbol)
              processor = processor_class.new_with_agnostic_args(
                declaration_data:,
                parent_declaration_data: strict_type_declaration
              )

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
