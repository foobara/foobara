module Foobara
  module BuiltinTypes
    module Model
      module Casters
        class Hash < Attributes::Casters::Hash
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def cast(attributes)
            model_class.new(super)
          end

          def model_class
            type = parent_declaration_data[:type]

            if type == :model
              Object.const_get(parent_declaration_data[:model_class])
            else
              Foobara::Namespace.current.foobara_lookup_type!(type).target_class
            end
          end
        end
      end
    end
  end
end
