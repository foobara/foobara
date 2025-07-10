module Foobara
  class DetachedEntity < Model
    module Concerns
      module Types
        include Concern

        def full_entity_name(...)
          self.class.full_entity_name(...)
        end

        def entity_name(...)
          self.class.entity_name(...)
        end

        module ClassMethods
          def entity_type
            return @model_type if defined?(@model_type)

            if attributes_type
              set_model_type
            end

            @model_type
          end

          def type_declaration(...)
            raise "No primary key set yet" unless primary_key_attribute

            super.merge(type: :detached_entity, primary_key: primary_key_attribute)
          end

          def set_model_type
            if primary_key_attribute
              super
            end
          end

          def foobara_primary_key_type
            @foobara_primary_key_type ||= attributes_type.element_types[primary_key_attribute]
          end

          alias primary_key_type foobara_primary_key_type

          def full_entity_name
            full_model_name
          end

          def entity_name
            model_name
          end
        end
      end
    end
  end
end
