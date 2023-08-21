module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformers
        class Defaults < Value::Transformer
          class << self
            def declaration_data_type_declaration
              :duck # TODO: fix this when we have a way to specify attributes with unspecified keys
            end
          end

          def transform(attributes_hash)
            defaults.merge(attributes_hash)
          end
        end
      end
    end
  end
end
