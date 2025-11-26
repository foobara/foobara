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
                    rawish_type_declaration.hash? && rawish_type_declaration[:one_of].is_a?(::Array)
                  end

                  def desugarize(rawish_type_declaration)
                    one_of = rawish_type_declaration[:one_of]

                    # TODO: for performance, can we just use the type identified by type: when possible?
                    type = type_for_declaration(rawish_type_declaration.except(:one_of))

                    rawish_type_declaration[:one_of] = one_of.map do |value|
                      type.process_value!(value)
                    end

                    rawish_type_declaration
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
