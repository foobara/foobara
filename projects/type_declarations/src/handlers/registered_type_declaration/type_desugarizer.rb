Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class TypeDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            # TODO: why do we enter here? Why not short-circuit since we already have the type??
            sugary_type_declaration.is_a?(Types::Type)
          end

          def desugarize(type)
            raise "wtf"
            type.reference_or_declaration_data
          end

          def priority
            Priority::FIRST - 1
          end
        end
      end
    end
  end
end
