module Foobara
  class Model
    class TypeBuilder
      class Attributes < TypeBuilder
        delegate :schemas, to: :schema

        def to_args
          super.merge(children_types:)
        end

        def children_types
          @children_types ||= schemas.transform_values do |schema|
            TypeBuilder.type_for(schema)
          end
        end
      end
    end
  end
end
