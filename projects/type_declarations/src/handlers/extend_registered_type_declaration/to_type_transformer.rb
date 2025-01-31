Foobara.require_project_file("type_declarations", "handlers/registered_type_declaration/to_type_transformer")
Foobara.require_project_file("type_declarations", "handlers/extend_associative_array_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredTypeDeclaration < RegisteredTypeDeclaration
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ToTypeTransformer < RegisteredTypeDeclaration::ToTypeTransformer
          def transform(strict_type_declaration)
            # TODO: maybe cache this stuff??
            base_type = super

            casters = []
            transformers = []
            validators = []
            element_processors = []

            additional_processors_to_apply = strict_type_declaration.except(*non_processor_keys)

            # TODO: validate the name
            additional_processors_to_apply.each_pair do |processor_symbol, declaration_data|
              processor_class = base_type.find_supported_processor_class(processor_symbol)
              processor = processor_class.new_with_agnostic_args(
                declaration_data:,
                parent_declaration_data: strict_type_declaration
              )

              category = case processor
                         when Value::Caster
                           casters
                         when Value::Validator
                           validators
                         when Value::Transformer
                           transformers
                         when Types::ElementProcessor
                           element_processors
                         else
                           # TODO: add validator that these are all fine so we don't have to bother here...
                           # :nocov:
                           raise "Not sure where to put #{processor}"
                           # :nocov:
                         end

              category << processor
            end

            type_class.new(
              strict_type_declaration,
              base_type:,
              # description: strict_type_declaration.is_a?(::Hash) && strict_type_declaration[:description],
              description: strict_type_declaration[:description],
              casters:,
              transformers:,
              validators:,
              element_processors:,
              # TODO: can't we just set this to [] here??
              target_classes: target_classes(strict_type_declaration),
              name: type_name(strict_type_declaration)
            )
          end

          def type_class
            Types::Type
          end

          # TODO: test that registering a custom type sets its name
          def type_name(strict_type_declaration)
            "Anonymous #{strict_type_declaration[:type]} extension"
          end

          def non_processor_keys
            %i[type _desugarized description]
          end
        end
      end
    end
  end
end
