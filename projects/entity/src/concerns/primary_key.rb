module Foobara
  class Entity < Model
    module Concerns
      module PrimaryKey
        include Concern

        foobara_delegate :primary_key_attribute, to: :class

        module ClassMethods
          attr_reader :primary_key_attribute

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

            @primary_key_attribute = attribute_name.to_sym

            set_model_type
          end
        end

        def primary_key
          read_attribute(primary_key_attribute)
        end
      end
    end
  end
end