require "foobara/nested_transactionable"

module Foobara
  module CommandPatternImplementation
    module Concerns
      module Transactions
        include Concern
        include NestedTransactionable

        def relevant_entity_classes
          return @relevant_entity_classes if defined?(@relevant_entity_classes)

          entity_classes = if inputs_type
                             relevant_entity_classes_for_type(inputs_type)
                           else
                             []
                           end

          if result_type
            entity_classes += relevant_entity_classes_for_type(result_type)
          end

          @relevant_entity_classes = [*entity_classes, *self.class.depends_on_entities].uniq
        end
      end
    end
  end
end
