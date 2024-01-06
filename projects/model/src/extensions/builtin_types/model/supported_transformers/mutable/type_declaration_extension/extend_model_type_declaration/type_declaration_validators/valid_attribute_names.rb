module Foobara
  module BuiltinTypes
    module Model
      module SupportedTransformers
        class Mutable < TypeDeclarations::Transformer
          module TypeDeclarationExtension
            module ExtendModelTypeDeclaration
              module TypeDeclarationValidators
                class ValidAttributeNames < TypeDeclarations::TypeDeclarationValidator
                  class InvalidMutableValueGivenError < Value::DataError
                    class << self
                      def context_type_declaration
                        {
                          invalid_key: :symbol,
                          valid_attribute_names: [:symbol],
                          mutable: [:symbol]
                        }
                      end
                    end
                  end

                  def applicable?(value)
                    binding.pry
                    if value.is_a?(::Hash) && value.key?(:mutable) && value.key?(:type)
                      mutable = value[:mutable]

                      if mutable.is_a?(::Array)
                        type = type_for_declaration(value[:type])

                        type.extends_symbol?(:model)
                      end
                    end
                  end

                  def validation_errors(strict_type_declaration)
                    binding.pry
                    mutable = strict_type_declaration[:mutable]

                    binding.pry

                    model_type = type_for_declaration(strict_type_declaration[:type])

                    valid_attribute_names = model_type.element_types.keys

                    mutable.map do |key|
                      unless valid_attribute_names.include?(key)
                        build_error(
                          message: "#{key} is not a valid attribute, expected one of #{valid_attribute_names}",
                          context: {
                            invalid_key: key,
                            valid_attribute_names:,
                            mutable:
                          }
                        )
                      end
                    end.compact
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
