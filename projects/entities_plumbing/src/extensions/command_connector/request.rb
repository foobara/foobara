module Foobara
  class CommandConnector
    class Request
      def relevant_entity_classes
        if command_class.is_a?(::Class) && command_class < TransformedCommand
          if authenticator.respond_to?(:relevant_entity_classes)
            entity_classes = authenticator.relevant_entity_classes(self)
            [*entity_classes, *relevant_entity_classes_from_inputs_transformer]
          else
            relevant_entity_classes_from_inputs_transformer
          end
        end || EMPTY_ARRAY
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
    end
  end
end
