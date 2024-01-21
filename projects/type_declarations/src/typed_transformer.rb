module Foobara
  module TypeDeclarations
    # TODO: this should instead be a processor and have its own possible_errors
    class TypedTransformer < Value::Transformer
      class << self
        def input_type_declaration
          nil
        end

        def output_type_declaration
          nil
        end

        def input_type
          return @input_type if defined?(@input_type)

          @input_type = if input_type_declaration
                          Domain.current.foobara_type_from_declaration(input_type_declaration)
                        end
        end

        def output_type
          return @output_type if defined?(@output_type)

          @output_type = if output_type_declaration
                           Domain.current.foobara_type_from_declaration(output_type_declaration)
                         end
        end
      end

      foobara_delegate :input_type, :output_type, to: :class

      def process_value(value)
        input = if input_type
                  input_outcome = input_type.process_value(value)
                  input_outcome.success? ? input_outcome.result : value
                else
                  value
                end

        output = transform(input)

        if output_type
          output = output_type.process_value!(output)
        end

        Outcome.success(output)
      end
    end
  end
end
