Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # type_symbol is basically just a flag that lets us know that type is fully qualified.
        # rather hacky but other potential workarounds seemed gnarlier
        class StrictStringifiedDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            # TODO: we shouldn't have to check if this is a hash. This means some other desugarizer is unnecessarily
            # processing a type declaration as if it were sugary. Find and fix that to speed this up a tiny bit.
            sugary_type_declaration.hash? && sugary_type_declaration.strict_stringified?
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.symbolize_keys!
            sugary_type_declaration[:type] = sugary_type_declaration[:type].to_sym

            sugary_type_declaration
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
