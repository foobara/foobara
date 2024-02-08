module Foobara
  module BuiltinTypes
    module Duck
      module SupportedValidators
        class OneOf < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendRegisteredTypeDeclaration
              module Desugarizers
                class ModuleDesugarizer < TypeDeclarations::Desugarizer
                  def applicable?(rawish_type_declaration)
                    rawish_type_declaration.is_a?(::Hash) && rawish_type_declaration[:one_of].is_a?(::Module)
                  end

                  def desugarize(rawish_type_declaration)
                    mod = rawish_type_declaration[:one_of]

                    one_of = Util.constant_values(mod)

                    rawish_type_declaration.merge(one_of:)
                  end

                  def priority
                    Priority::LOW
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
