module Foobara
  module BuiltinTypes
    module Duck
      module SupportedValidators
        class InstanceOf < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendRegisteredTypeDeclaration
              module Desugarizers
                class ClassTypeDesugarizer < TypeDeclarations::Desugarizer
                  def applicable?(rawish_type_declaration)
                    return false unless rawish_type_declaration.hash?

                    rawish_type_declaration[:type].is_a?(::Class)
                  end

                  def desugarize(rawish_type_declaration)
                    klass = rawish_type_declaration[:type]

                    rawish_type_declaration[:type] = :duck
                    rawish_type_declaration[:instance_of] = klass.name
                    rawish_type_declaration.is_absolutified = true

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
