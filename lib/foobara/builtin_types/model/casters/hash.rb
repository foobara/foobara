module Foobara
  module BuiltinTypes
    module Model
      module Casters
        class Hash < Attributes::Casters::Hash
          def cast(attributes)
            model_class.new(super)
          end

          def model_class
            declaration_data[:model_class]
          end
        end
      end
    end
  end
end
