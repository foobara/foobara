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
                    return false unless rawish_type_declaration.is_a?(::Hash)

                    rawish_type_declaration[:type].is_a?(::Class)
                  end

                  def desugarize(rawish_type_declaration)
                    klass = rawish_type_declaration[:type]
                    rawish_type_declaration.merge(type: :duck, instance_of: klass.name)
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
