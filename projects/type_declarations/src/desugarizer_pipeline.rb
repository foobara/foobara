module Foobara
  module TypeDeclarations
    class DesugarizerPipeline < Value::Processor::Pipeline
      def applicable?(type_declaration)
        !type_declaration.strict? && super
      end
    end
  end
end
