Foobara.require_project_file("type_declarations", "handlers/extend_registered_type_declaration")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendAssociativeArrayTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          strictish_type_declaration = if sugary_type_declaration.strict?
                                         sugary_type_declaration
                                       else
                                         desugarize(sugary_type_declaration.clone)
                                       end

          if strictish_type_declaration.hash? && strictish_type_declaration[:type] == :associative_array
            unless strictish_type_declaration.equal?(sugary_type_declaration)
              sugary_type_declaration.assign(strictish_type_declaration)
            end

            true
          end
        end

        # TODO: do we really need this? Isn't this the default?
        def priority
          Priority::LOW
        end
      end
    end
  end
end
