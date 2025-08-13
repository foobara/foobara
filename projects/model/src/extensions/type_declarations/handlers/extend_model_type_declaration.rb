module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        def applicable?(sugary_type_declaration)
          if sugary_type_declaration.hash?
            strict_type_declaration = if sugary_type_declaration.strict?
                                        sugary_type_declaration
                                      else
                                        desugarize(sugary_type_declaration.clone)
                                      end

            if strict_type_declaration[:type] == expected_type_symbol
              unless sugary_type_declaration.equal?(strict_type_declaration)
                sugary_type_declaration.assign(strict_type_declaration)
              end

              true
            end
          end
        end

        def expected_type_symbol
          :model
        end

        def priority
          Priority::LOW
        end
      end
    end
  end
end
