module Foobara
  class DetachedEntity < Model
    module Concerns
      module Aliases
        include Concern

        module ClassMethods
          def depends_on(...)
            foobara_depends_on(...)
          end

          def deep_depends_on(...)
            foobara_deep_depends_on(...)
          end

          def associations(...)
            foobara_associations(...)
          end

          def deep_associations(...)
            foobara_deep_associations(...)
          end

          def attributes_type(...)
            foobara_attributes_type(...)
          end

          def primary_key_attribute(...)
            foobara_primary_key_attribute(...)
          end

          def model_name(...)
            foobara_model_name(...)
          end
        end
      end
    end
  end
end
