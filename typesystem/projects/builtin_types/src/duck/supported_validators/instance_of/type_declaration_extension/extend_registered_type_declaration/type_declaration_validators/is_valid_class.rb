module Foobara
  module BuiltinTypes
    module Duck
      module SupportedValidators
        class InstanceOf < TypeDeclarations::Validator
          module TypeDeclarationExtension
            module ExtendRegisteredTypeDeclaration
              module TypeDeclarationValidators
                class IsValidClass < TypeDeclarations::TypeDeclarationValidator
                  class InvalidInstanceOfValueGivenError < Value::DataError
                    class << self
                      def message
                        "instance_of: should be a class or the name of an existing class"
                      end
                    end
                  end

                  def applicable?(strict_type_declaration)
                    strict_type_declaration.hash? && strict_type_declaration.key?(:instance_of)
                  end

                  def validation_errors(strict_type_declaration)
                    instance_of = strict_type_declaration[:instance_of]

                    return if instance_of.is_a?(::Class)

                    if instance_of.is_a?(::String) || instance_of.is_a?(::Symbol)
                      unless Object.const_defined?(instance_of)
                        build_error(context: { attribute_name: :instance_of, value: instance_of })
                      end
                    else
                      build_error(context: { attribute_name: :instance_of, value: instance_of })
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
end
