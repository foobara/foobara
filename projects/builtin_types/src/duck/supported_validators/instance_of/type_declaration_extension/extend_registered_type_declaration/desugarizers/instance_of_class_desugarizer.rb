module Foobara
  module BuiltinTypes
    module Duck
      module SupportedValidators
        class InstanceOf < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendRegisteredTypeDeclaration
              module Desugarizers
                class InstanceOfClassDesugarizer < TypeDeclarations::Desugarizer
                  def applicable?(rawish_type_declaration)
                    rawish_type_declaration.hash? && rawish_type_declaration[:instance_of].is_a?(::Class)
                  end

                  def desugarize(rawish_type_declaration)
                    rawish_type_declaration[:instance_of] = rawish_type_declaration[:instance_of].name
                    rawish_type_declaration
                  end

                  def priority
                    Priority::LOWEST + 1
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
