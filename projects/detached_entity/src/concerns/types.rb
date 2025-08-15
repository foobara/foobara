module Foobara
  class DetachedEntity < Model
    module Concerns
      module Types
        include Concern

        foobara_delegate :full_entity_name, :entity_name, to: :class

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

            declaration = super

            declaration[:type] = :detached_entity
            declaration[:primary_key] = primary_key_attribute
            declaration.is_absolutified = true

            declaration
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
