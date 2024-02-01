module Foobara
  module CommandConnectors
    class Request
      # TODO: this feels like a smell of some sort...
      attr_accessor :command_class, :command, :error, :command_connector, :serializers

      def full_command_name
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def inputs
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
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
        command.outcome
      end

      def result
        outcome.result
      end

      def error_collection
        outcome.error_collection
      end

      private

      def objects_to_serializers(objects)
        objects.map do |object|
          case object
          when Class
            object.new(self)
          when Value::Processor
            object
          when ::Symbol, ::String
            klass = Serializer.serializer_from_symbol(object)

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
