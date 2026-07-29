module Foobara
  module CommandPatternImplementation
    module Concerns
      module ModelInputsType
        include Concern

        module ClassMethods
          def inputs(*args, **opts, &)
            if args.size == 1 && opts.empty?
              type = args.first

              if type.is_a?(::Class) && (type == Model || type < Model)
                type = type.model_type
              end

              unless skip_model_to_attributes_conversion?(type)
                if type.extends?(BuiltinTypes[:model])
                  return super(type.element_types)
                end
              end
            end

            super
          end

          private

          def skip_model_to_attributes_conversion?(type)
            !type.is_a?(Foobara::Type)
          end
        end
      end
    end
  end
end
