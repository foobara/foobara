module Foobara
  class CommandConnector
    class Authenticator
      def relevant_entity_classes(_request)
        if to_type&.extends?(BuiltinTypes[:entity])
          NestedTransactionable.relevant_entity_classes_for_type(to_type)
        else
          EMPTY_ARRAY
        end
      end
    end
  end
end
