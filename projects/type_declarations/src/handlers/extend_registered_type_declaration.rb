require_relative "registered_type_declaration"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredTypeDeclaration < RegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          strict_type_declaration = if sugary_type_declaration.strict?
                                      # :nocov:
                                      sugary_type_declaration
                                      # :nocov:
                                    else
                                      desugarize(sugary_type_declaration.clone)
                                    end

          return false unless strict_type_declaration.hash?
          # if there's no processors to extend the existing type with, then we don't handle that here
          return false if strict_type_declaration.declaration_data.keys == [:type]

          applicable = super(strict_type_declaration.slice(:type))

          if applicable && !sugary_type_declaration.equal?(strict_type_declaration)
            sugary_type_declaration.assign(strict_type_declaration)
          end

          applicable
        end

        def priority
          Priority::LOWEST
        end
      end
    end
  end
end
