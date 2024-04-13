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
                    rawish_type_declaration.is_a?(::Hash) && rawish_type_declaration[:instance_of].is_a?(::Class)
                  end

                  def desugarize(rawish_type_declaration)
                    instance_of = rawish_type_declaration[:instance_of]
                    instance_of = instance_of.name
                    rawish_type_declaration.merge(instance_of:)
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
