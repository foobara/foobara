module Foobara
  class Command
    module Concerns
      module Reflection
        extend ActiveSupport::Concern

        def initialize(...)
          self.class.all << self
          super(...)
        end

        class_methods do
          def all
            @all ||= []
          end

          def reset_all
            @all = nil
          end

          def to_h
            h = {
              command_name:,
              inputs_type: inputs_type&.declaration_data,
              error_types: errors_type_declaration,
              depends_on: depends_on.map(&:to_s)
            }

            if result_type
              h.merge!(result_type: result_type.declaration_data)
            end

            h
          end

          def command_name
            name&.demodulize
          end
        end

        delegate :type_for_declaration, to: :class
      end
    end
  end
end
