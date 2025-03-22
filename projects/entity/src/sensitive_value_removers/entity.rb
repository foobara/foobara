module Foobara
  class Entity < DetachedEntity
    module SensitiveValueRemovers
      class Entity < TypeDeclarations::RemoveSensitiveValuesTransformer
        def transform(record)
          puts type.scoped_full_name
          binding.pry
          record
        end
      end
    end
  end
end
