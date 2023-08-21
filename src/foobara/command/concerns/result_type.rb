module Foobara
  class Command
    module Concerns
      module ResultType
        extend ActiveSupport::Concern

        class_methods do
          def result(result_type_declaration)
            @result_type = type_for_declaration(result_type_declaration)
          end

          def result_type
            return @result_type if defined?(@result_type)

            @result_type = if superclass < Foobara::Command
                             superclass.result_type
                           end
          end

          def raw_result_type_declaration
            result_type.raw_declaration_data
          end
        end

        delegate :result_type, :raw_result_type_declaration, to: :class
      end
    end
  end
end
