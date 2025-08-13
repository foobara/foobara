Foobara.require_project_file("type_declarations", "desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # type_symbol is basically just a flag that lets us know that type is fully qualified.
        # rather hacky but other potential workarounds seemed gnarlier
        # TODO: why does this exist? If it's strict doesn't that mean there's nothing left to do??
        class StrictDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(strict_type_declaration)
            unless strict_type_declaration.is_a?(TypeDeclaration)
              binding.pry
              raise "wtf"
            end
            # TODO: we shouldn't have to check if this is a hash. This means some other desugarizer is unnecessarily
            # processing a type declaration as if it were sugary. Find and fix that to speed this up a tiny bit.
            if strict_type_declaration.hash? && strict_type_declaration.strict?
              unless strict_type_declaration.absolutified?
                raise "wtf"
              end
            end
            # TODO: delete this whole desugarizer now that we don't need _desugarized hack
          end

          def desugarize(strict_type_declaration)
            raise "wtf"
            desugarized = strict_type_declaration[:_desugarized] || {}
            desugarized[:type_absolutified] = true
            strict_type_declaration.merge(_desugarized: desugarized)
          end

          def priority
            Priority::FIRST
          end
        end
      end
    end
  end
end
