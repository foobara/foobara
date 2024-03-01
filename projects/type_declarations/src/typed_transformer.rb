module Foobara
  module TypeDeclarations
    # TODO: this should instead be a processor and have its own possible_errors
    class TypedTransformer < Value::Transformer
      class << self
        # A,B,C,D
        # let's say this transformer is C...
        # If we are a noop, then we are going to output D.input_type and we expect B.input_type
        # We obviously have a problem if D is incompatible with our output type.
        # We need to know B.output_type in order to say what we are going to output.
        #
        # Conversely, we need to know what D expects in order to say what we expect to receive (sometimes)
        #
        # So logic is... For C to say what its input_type is, it must know B's output_type.
        # or... I guess for an inputs transformer, we need to know what D expects as its input_type, right?
        # since we have an obligation be compatible with it.
        #
        # Use case 1:
        # 1. Command takes model A
        # 2. we want an inputs transformer that takes A.attributes_type
        # 3. Therefore its input_type is A.attributes_type
        # 4. And also, its output type is A.attributes_type in this case since there's no need to actually create the models.
        # 5. So to tell our input_type, we must know the input_type of what comes next.
        #
        # Use case 2:
        # 1. Command takes foo: :integer but we want to take bar: :string
        # 2. transformer has this hard-coded knowledge.
        # 3. we don't need to receive either types to answer our input and output types.
        #
        # Use case 3: Changing a record into its primary key
        # 1. Command has result type of A which is an Entity
        # 2. transformer takes an A record and returns record.primary_key
        # 3. To know the output type, we need to know the result type of the previous type.
        # 4. To know the input type, we need to know the input_type of the previous transformer since they are the same.
        #    (however, by convention we can just use nil in this case.)
        #
        # Challenge: we seem to not know in advance if the transformer needs to know what comes before it or what comes
        # after it. Unless we are writing a one-off transformer then we have hard-coded knowledge.
        #
        # Seems like input transformer really needs to know what comes next, the target type.
        # Seems like output transformer might require to know what came previously
        def input_type_declaration(_previous_input_type)
          nil
        end

        def output_type_declaration(_previous_output_type)
          nil
        end

        def input_type(previous_input_type)
          return @input_type if defined?(@input_type)

          @input_type = if input_type_declaration
                          binding.pry
                          Domain.current.foobara_type_from_declaration(input_type_declaration(previous_input_type))
                        end
        end

        def output_type(previous_output_type)
          return @output_type if defined?(@output_type)

          @output_type = if output_type_declaration
                           Domain.current.foobara_type_from_declaration(output_type_declaration(previous_output_type))
                         end
        end
      end

      foobara_delegate :input_type, :output_type, to: :class

      def process_value(value)
        binding.pry
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
