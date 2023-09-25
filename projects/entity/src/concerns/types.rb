module Foobara
  class Entity < Model
    module Concerns
      module Types
        include Concern

        module ClassMethods
          def entity_type
            model_type
          end

          def type_declaration(...)
            raise "No primary key set yet" unless primary_key_attribute

            super.merge(type: :entity, primary_key: primary_key_attribute)
          end

          def set_model_type
            if primary_key_attribute
              super
            end
          end

          def primary_key_type
            @primary_key_type ||= attributes_type.element_types[primary_key_attribute]
          end
        end
      end
    end
  end
end