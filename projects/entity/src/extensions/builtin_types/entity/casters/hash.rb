module Foobara
  module BuiltinTypes
    module Entity
      module Casters
        class Hash < Foobara::BuiltinTypes::Model::Casters::Hash
          def cast(attributes)
            raise "why cast a hash?? unclear if created or not"
            model_class.new(super)
          end
        end
      end
    end
  end
end
