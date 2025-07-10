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

          def raw_result_type_declaration
            result_type.raw_declaration_data
          end
        end

        def result_type(...)
          self.class.result_type(...)
        end

        def raw_result_type_declaration(...)
          self.class.raw_result_type_declaration(...)
        end
      end
    end
  end
end
