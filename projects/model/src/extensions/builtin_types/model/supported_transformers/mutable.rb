module Foobara
  module BuiltinTypes
    module Model
      # TODO: Create SupportedMutations concept
      module SupportedTransformers
        class Mutable < TypeDeclarations::Transformer
          def mutable_fields
            declaration_data
          end

          def transform(model)
            model.mutable = mutable_fields
            model
          end

          def error_message(value)
            "Max exceeded. #{value} is larger than #{max}"
          end

          def error_context(value)
            {
              value:,
              max:
            }
          end
        end
      end
    end
  end
end
