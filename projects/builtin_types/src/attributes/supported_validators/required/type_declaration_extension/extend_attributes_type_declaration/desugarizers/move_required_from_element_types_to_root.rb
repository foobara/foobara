module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedValidators
        class Required < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendAttributesTypeDeclaration
              module Desugarizers
                class MoveRequiredFromElementTypesToRoot < TypeDeclarations::Desugarizer
                  def applicable?(value)
                    return false if value.strict?

                    value.hash? && value[:type] == :attributes && value.key?(:element_type_declarations)
                  end

                  def desugarize(rawish_type_declaration)
                    required_attributes = Util.array(rawish_type_declaration[:required])
                    # TODO: move this to a transformer...
                    required_attributes = required_attributes.map do |value|
                      if value.is_a?(::String)
                        value.to_sym
                      else
                        value
                      end
                    end

                    element_type_declarations = rawish_type_declaration[:element_type_declarations]

                    changed = false

                    element_type_declarations.each_pair do |attribute_name, attribute_type_declaration|
                      if attribute_type_declaration.is_a?(::Hash) && attribute_type_declaration.key?(:required)
                        is_required = attribute_type_declaration[:required]

                        if is_required == true || is_required == false
                          element_type_declarations[attribute_name] = attribute_type_declaration.except(:required)

                          changed = true

                          if is_required
                            required_attributes << attribute_name
                          else
                            required_attributes.delete(attribute_name)
                          end
                        end
                      end
                    end

                    if required_attributes.empty?
                      rawish_type_declaration.delete(:required)
                    else
                      rawish_type_declaration[:required] = required_attributes
                    end

                    if changed
                      rawish_type_declaration[:element_type_declarations] = element_type_declarations
                    end

                    rawish_type_declaration
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
