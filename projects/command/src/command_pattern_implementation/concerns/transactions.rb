module Foobara
  module CommandPatternImplementation
    module Concerns
      module Transactions
        include Concern
        include NestedTransactionable

        def relevant_entity_classes
          @relevant_entity_classes ||= begin
            entity_classes = if inputs_type
                               Entity.construct_associations(
                                 inputs_type
                               ).values.uniq.map(&:target_class)
                             else
                               []
                             end

            if result_type
              entity_classes += Entity.construct_associations(
                result_type
              ).values.uniq.map(&:target_class)

              if result_type.extends?(BuiltinTypes[:entity])
                entity_classes << result_type.target_class
              end
            end

            entity_classes += entity_classes.uniq.map do |entity_class|
              entity_class.deep_associations.values
            end.flatten.uniq.map(&:target_class)

            [*entity_classes, *self.class.depends_on_entities].uniq
          end
        end
      end
    end
  end
end
