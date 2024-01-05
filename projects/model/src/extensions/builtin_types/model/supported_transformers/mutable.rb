module Foobara
  module BuiltinTypes
    module Model
      module SupportedTransformers
        class Mutable < TypeDeclarations::Transformer
          def mutable_fields
            declaration_data
          end

          def transform(model)
            if mutable_fields
              model.mutable = mutable_fields
            end

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
