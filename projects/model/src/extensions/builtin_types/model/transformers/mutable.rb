module Foobara
  module BuiltinTypes
    module Model
      # TODO: Create Mutations/SupportedMutations concept
      class Transformers
        class Mutable < TypeDeclarations::Transformer
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def transform(record)
            record.mutable = if parent_declaration_data.key?(:mutable)
                               parent_declaration_data[:mutable]
                             else
                               false
                             end

            record
          end
        end
      end
    end
  end
end
