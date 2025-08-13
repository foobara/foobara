Foobara.require_project_file("type_declarations", "handlers/extend_attributes_type_declaration/hash_desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAttributesTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        class DslDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.proc?
          end

          def desugarize(block)
            Foobara::TypeDeclarations::Dsl::Attributes.to_declaration(&block)
          end

          def priority
            # TODO: need a way to express that we must run after/before other processors so that we could just say
            # we are higher priority than the HashDesugarizer...
            Priority::HIGH - 1
          end
        end
      end
    end
  end
end
