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
            symbolized_attributes = super

            model_class.send(build_method(symbolized_attributes), symbolized_attributes)
          end

          def model_class
            type = parent_declaration_data[:type]

            if type == expected_type_symbol
              model_class_name = parent_declaration_data[:model_class]

              if Object.const_defined?(model_class_name)
                Object.const_get(parent_declaration_data[:model_class])
              else
                Namespace.current.foobara_lookup_type!(model_class_name).target_class
              end
            else
              Namespace.current.foobara_lookup_type!(type).target_class
            end
          end

          def expected_type_symbol
            :model
          end

          def build_method(_symbolized_attributes)
            :new
          end
        end
      end
    end
  end
end
