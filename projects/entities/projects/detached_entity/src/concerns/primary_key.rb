module Foobara
  class DetachedEntity < Model
    module Concerns
      module PrimaryKey
        include Concern

        def primary_key_attribute
          self.class.primary_key_attribute
        end

        module ClassMethods
          def primary_key(attribute_name)
            if primary_key_attribute
              # :nocov:
              raise "Primary key already set to #{primary_key_attribute}"
              # :nocov:
            end

            if attribute_name.nil? || attribute_name.empty?
              # :nocov:
              raise ArgumentError, "Primary key can't be blank"
              # :nocov:
            end

            @foobara_primary_key_attribute = attribute_name.to_sym

            set_model_type
          end

          def foobara_primary_key_attribute
            return @foobara_primary_key_attribute if @foobara_primary_key_attribute

            if superclass != DetachedEntity && superclass.respond_to?(:foobara_primary_key_attribute)
              @foobara_primary_key_attribute = superclass.foobara_primary_key_attribute
            end
          end

          alias primary_key_attribute foobara_primary_key_attribute
        end

        def primary_key
          read_attribute(primary_key_attribute)
        end
      end
    end
  end
end
