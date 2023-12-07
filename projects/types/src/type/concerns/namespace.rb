module Foobara
  module Types
    class Type < Value::Processor::Pipeline
      module Concerns
        module Namespace
          include Concern

          def scoped_path
            [type_symbol]
          end
        end
      end
    end
  end
end
