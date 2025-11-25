require "inheritable_thread_vars"

module Foobara
  module BuiltinTypes
    module Attributes
      module Transformers
        class RemoveUnexpectedAttributes < Value::Transformer
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def applicable?(hash)
            Thread.inheritable_thread_local_var_get(:foobara_ignore_unexpected_attributes) &&
              unexpected_attributes(hash).any?
          end

          def transform(hash)
            hash.except(*unexpected_attributes(hash))
          end

          def unexpected_attributes(hash)
            hash.keys - parent_declaration_data[:element_type_declarations].keys
          end
        end
      end
    end
  end
end
