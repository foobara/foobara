module Foobara
  module TypeDeclarations
    # TODO: this should instead be a processor and have its own possible_errors
    class TypedTransformer < Value::Transformer
      class << self
        # A,B,C,D
        # let's say this transformer is C...
        # If we are a noop, then we are going to output D.type and we expect B.type
        # We obviously have a problem if D is incompatible with our output type.
        # We need to know B.output_type in order to say what we are going to output.
        #
        # Conversely, we need to know what D expects in order to say what we expect to receive (sometimes)
        #
        # So logic is... For C to say what its type is, it must know B's output_type.
        # or... I guess for an inputs transformer, we need to know what D expects as its type, right?
        # since we have an obligation be compatible with it.
        #
        # Use case 1: command line interface gets awkward with models
        # 1. Command takes model A
        # 2. we want an inputs transformer that takes A.attributes_type
        # 3. Therefore its type is A.attributes_type
        # 4. And also, its output type is A.attributes_type in this case since there's no need to actually create the
        #    models.
        # 5. So to tell our type, we must know the type of what comes next.
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
        # 4. To know the input type, we need to know the type of the previous transformer since they are the same.
        #    (however, by convention we can just use nil in this case.)
        #
        # Use case 4: document upload
        # 1. Command takes input stream plus some document info
        # 2. controller action receives temporary file path
        # 3. transformer opens input stream and replaces file path with input stream
        # 4. In this case, we have hard-coded types.
        #
        # Challenge: we seem to not know in advance if the transformer needs to know what comes before it or what comes
        # after it. Unless we are writing a one-off transformer then we have hard-coded knowledge.
        #
        # Seems like input transformer really needs to know what comes next, the target type.
        # Seems like output transformer might require to know what came previously
        #
        # Plan:
        # 1. Both inputs transformer and result have similar structure... they have a relevant type that they transform.
        # The difference is that the result takes previous steps output and transforms it to a different type, whereas
        # the input transformer needs to know what comes next in order to communicate its types.
        # So we might be able to get away with a transformed_type that accepts the from_type. And the calling code can
        # interpret how it goes. This might create some awkwardness or confusion at least when creating one of the
        # two types of transformer.
        def type_declaration(_from_type)
          nil
        end

        def type(from_type)
          dec = type_declaration(from_type)

          if dec
            if dec.is_a?(Types::Type)
              dec
            else
              Domain.current.foobara_type_from_declaration(dec)

            end
          end
        end
      end

      alias from_type declaration_data

      def type
        return @type if @type

        @type = self.class.type(from_type)
      end

      def process_value(value)
        output = transform(value)
        Outcome.success(output)
      end
    end
  end
end
