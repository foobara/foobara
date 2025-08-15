module Foobara
  module CommandPatternImplementation
    module Concerns
      module ResultType
        include Concern

        module ClassMethods
          def result(...)
            @result_type = type_for_declaration(...)
          end

          def result_type
            return @result_type if defined?(@result_type)

            @result_type = if superclass < Foobara::Command
                             superclass.result_type
                           end
          end
        end

        foobara_delegate :result_type, :raw_result_type_declaration, to: :class
      end
    end
  end
end
