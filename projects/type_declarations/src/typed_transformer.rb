module Foobara
  module TypeDeclarations
    # TODO: this should instead be a processor and have its own possible_errors
    class TypedTransformer < Value::Transformer
      def input_type_declaration
        nil
      end

      def output_type_declaration
        nil
      end

      def input_type
        return @input_type if defined?(@input_type)

        @input_type = if input_type_declaration
                        Namespace.current.type_for_declaration(input_type_declaration)
                      end
      end

      def output_type
        return @output_type if defined?(@output_type)

        @output_type = if output_type_declaration
                         Namespace.current.type_for_declaration(output_type_declaration)
                       end
      end

      def process_value(value)
        input_outcome = input_type.process_value(value)

        input = input_outcome.success? ? input_outcome.result : value

        output = if applicable?(input)
                   output_type.process_value!(transform(input))
                 else
                   value
                 end

        Outcome.success(output)
      end
    end
  end
end
