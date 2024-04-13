module Foobara
  module BuiltinTypes
    module Duck
      module SupportedValidators
        class InstanceOf < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendRegisteredTypeDeclaration
              module Desugarizers
                class ClassDesugarizer < TypeDeclarations::Desugarizer
                  def applicable?(rawish_type_declaration)
                    rawish_type_declaration.is_a?(::Class)
                  end

                  def desugarize(rawish_type_declaration)
                    { type: :duck, instance_of: rawish_type_declaration.name }
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
