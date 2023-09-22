module Foobara
  class Command
    module Concerns
      module Reflection
        include Concern

        def initialize(...)
          self.class.all << self
          super(...)
        end

        module ClassMethods
          def all
            @all ||= []
          end

          def reset_all
            remove_instance_variable("@all") if instance_variable_defined?("@all")
          end

          def manifest
            h = Util.remove_empty(
              error_types: errors_type_declaration,
              depends_on: depends_on.map(&:to_s)
            )

            if inputs_type
              h[:inputs_type] = inputs_type&.declaration_data
            end

            if result_type
              h[:result_type] = result_type.declaration_data
            end

            h
          end

          def manifest_hash
            {
              command_name.to_sym => manifest
            }
          end

          def command_name
            Util.non_full_name(self)
          end
        end

        foobara_delegate :type_for_declaration, to: :class
      end
    end
  end
end