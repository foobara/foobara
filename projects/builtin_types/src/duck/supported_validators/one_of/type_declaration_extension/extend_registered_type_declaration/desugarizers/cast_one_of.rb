module Foobara
  module BuiltinTypes
    module Duck
      module SupportedValidators
        class OneOf < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendRegisteredTypeDeclaration
              module Desugarizers
                class CastOneOf < TypeDeclarations::Desugarizer
                  def applicable?(rawish_type_declaration)
                    rawish_type_declaration.is_a?(::Hash) && rawish_type_declaration[:one_of].is_a?(::Array)
                  end

                  def desugarize(rawish_type_declaration)
                    one_of = rawish_type_declaration[:one_of]

                    type = type_for_declaration(rawish_type_declaration.except(:one_of))

                    one_of = one_of.map do |value|
                      type.process_value!(value)
                    end

                    rawish_type_declaration.merge(one_of:)
                  end

                  def priority
                    Priority::LOW + 1
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
