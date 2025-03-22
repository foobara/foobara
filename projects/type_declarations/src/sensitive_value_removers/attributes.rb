require_relative "../remove_sensitive_values_transformer"

module Foobara
  module TypeDeclarations
    module SensitiveValueRemovers
      class Attributes < RemoveSensitiveValuesTransformer
        def transform(attributes)
          attributes
        end
      end
    end
  end
end
