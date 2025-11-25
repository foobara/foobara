module Foobara
  class CommandConnector
    class Request
      include TruncatedInspect
      include NestedTransactionable

      # TODO: this feels like a smell of some sort...
      attr_accessor :command,
                    :command_class,
                    :error,
                    :command_connector,
                    # Why aren't there serializers on the response?
                    :serializers,
                    :inputs,
                    :full_command_name,
                    :action,
                    :response,
                    :authenticated_user,
                    :authenticated_credential

      def initialize(**opts)
        valid_keys = [:inputs, :full_command_name, :action, :serializers]

        invalid_keys = opts.keys - valid_keys

        unless invalid_keys.empty?
          # :nocov:
          raise ArgumentError, "invalid keys: #{invalid_keys} expected only #{valid_keys}"
          # :nocov:
        end

        self.inputs = opts[:inputs] if opts.key?(:inputs)
        self.action = opts[:action] if opts.key?(:action)
        self.full_command_name = opts[:full_command_name] if opts.key?(:full_command_name)
        self.serializers = Util.array(opts[:serializers]) if opts.key?(:serializers)
      end

      def mutate_request
        return if error

        # TODO: we really need to revisit these interfaces. Something is wrong.
        if command_class.respond_to?(:mutate_request)
          command_class.mutate_request(self)
        end
      end

      def authenticate
        return if error
        return unless command_class.respond_to?(:requires_authentication) && command_class.requires_authentication

        authenticated_user, authenticated_credential = authenticator.authenticate(self)

        # TODO: why are these on the command instead of the request??
        self.authenticated_user = authenticated_user
        self.authenticated_credential = authenticated_credential

        unless authenticated_user
          self.error = CommandConnector::UnauthenticatedError.new
        end
      end

      def authenticator
        command_class.authenticator
      end

      def serializer
        return @serializer if defined?(@serializer)

        if serializers.nil? || serializers.empty?
          @serializer = nil
          return
        end

        actual_serializers = objects_to_serializers(serializers)

        @serializer = if actual_serializers.size == 1
                        actual_serializers.first
                      else
                        Value::Processor::Pipeline.new(processors: actual_serializers)
                      end
      end

      def response_body
        @response_body ||= begin
          # TODO: should we have separate ways to register success and failure serializers?
          body = success? ? result : error_collection

          if serializer
            serializer.process_value!(body)
          else
            body
          end
        end
      end

      def success?
        outcome.success?
      end

      def outcome
        if error
          Outcome.error(error)
        else
          command&.outcome
        end
      end

      def result
        outcome.result
      end

      def error_collection
        outcome.error_collection
      end

      def relevant_entity_classes
        if command_class.is_a?(::Class) && command_class < TransformedCommand
          entity_classes = authenticator&.relevant_entity_classes(self)
          [*entity_classes, *relevant_entity_classes_from_inputs_transformer]
        end || []
      end

      private

      def relevant_entity_classes_from_inputs_transformer(
        object = [*command_class.inputs_transformer, *command_class.result_transformer]
      )
        case object
        when TypeDeclarations::TypedTransformer
          relevant_entity_classes_from_inputs_transformer([*object.from_type, *object.to_type])
        when Types::Type
          relevant_entity_classes_for_type(object)
        when ::Array
          object.map do |o|
            relevant_entity_classes_from_inputs_transformer(o)
          end.flatten
        when Value::Processor::Pipeline
          relevant_entity_classes_from_inputs_transformer(object.processors)
        else
          []
        end
      end

      def objects_to_serializers(objects)
        objects.map do |object|
          case object
          when Class
            object.new(self)
          when Value::Processor
            object
          when ::Symbol, ::String
            klass = Foobara::CommandConnectors::Serializer.serializer_from_symbol(object)

            unless klass
              # :nocov:
              raise "Could not find serializer for #{object}"
              # :nocov:
            end

            klass.new(self)
          else
            if object.respond_to?(:call)
              Value::Transformer.create(transform: object)
            else
              # :nocov:
              raise "Not sure how to convert #{object} into a serializer"
              # :nocov:
            end
          end
        end
      end
    end
  end
end
