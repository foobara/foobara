module Foobara
  class DetachedEntity < Model
    class CannotReadAttributeOnUnloadedRecordError < StandardError; end

    module Concerns
      module Attributes
        include Concern

        def read_attribute(attribute_name)
          attribute_name = attribute_name.to_sym

          if attribute_name != self.class.primary_key_attribute
            unless can_read_attributes_other_than_primary_key?
              raise CannotReadAttributeOnUnloadedRecordError,
                    "Cannot read attribute #{attribute_name} on unloaded record"
            end
          end

          super
        end

        def can_read_attributes_other_than_primary_key?
          loaded?
        end
      end
    end
  end
end
