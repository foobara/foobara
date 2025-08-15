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
            return false unless sugary_type_declaration.hash? && sugary_type_declaration.strict_stringified?

            raise "wtf" unless sugary_type_declaration.absolutified?
            # TODO: delete this whole desugarizer now that we don't need _desugarized hack
          end

          def desugarize(sugary_type_declaration)
            raise "wtf"

            sugary_type_declaration.symbolize_keys!
            type_symbol = sugary_type_declaration[:type]

            type = lookup_type(type_symbol, mode: Namespace::LookupMode::ABSOLUTE)

            unless type.full_type_symbol == type_symbol.to_sym
              raise "wtf... why wouldn't these match???"
            end

            type_symbol = type.full_type_symbol

            sugary_type_declaration[:type] = type_symbol.to_sym
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
