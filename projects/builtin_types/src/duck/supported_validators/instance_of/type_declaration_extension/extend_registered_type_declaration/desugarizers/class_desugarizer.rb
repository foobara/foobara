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
                    rawish_type_declaration.class?
                  end

                  def desugarize(rawish_type_declaration)
                    rawish_type_declaration.declaration_data = {
                      type: :duck,
                      instance_of: rawish_type_declaration.declaration_data.name
                    }
                    rawish_type_declaration.is_strict = true
                    rawish_type_declaration.is_deep_duped = true
                    rawish_type_declaration.is_duped = true

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
