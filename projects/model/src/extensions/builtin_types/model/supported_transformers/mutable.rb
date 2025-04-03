module Foobara
  module BuiltinTypes
    module Model
      module SupportedTransformers
        class Mutable < TypeDeclarations::Transformer
          class << self
            def requires_declaration_data?
              true
            end

            def requires_parent_declaration_data?
              true
            end
          end

          def transform(record)
            if parent_declaration_data.key?(:mutable)
              # hmmmm.... can we really just arbitrarily clobber this?
              # wouldn't that be surprising to calling code that passes in a record/model?
              # One use-case of this seems to be to reduce the amount of possible errors a command reports
              # by declaring that only some subset or none of the attributes are mutable.
              # However, we shouldn't react to this by clobbering the mutable state of the record because it might not
              # be a fresh record fetched from a primary key it might be an already loaded record/model from some other
              # context and that context might be surprised to learn that we've clobbered its mutability status.
              # Solutions?
              # 1. In the case of models, we could duplicate the model if the mutable value is different.
              # 2. But what about entities? We almost need some sort of proxy entity that tightens the mutability?
              record.mutable = parent_declaration_data[:mutable]
            end

            record
          end
        end
      end
    end
  end
end
