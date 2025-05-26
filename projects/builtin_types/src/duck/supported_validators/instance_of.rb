module Foobara
  module BuiltinTypes
    module Duck
      module SupportedValidators
        class InstanceOf < TypeDeclarations::Validator
          class NotInstanceOfError < Foobara::Value::DataError
            class << self
              def context_type_declaration
                {
                  value: :duck,
                  expected_class_name: :string
                }
              end
            end
          end

          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def applicable?(value)
            !value.nil? || !parent_declaration_data[:allow_nil]
          end

          def expected_class_name
            declaration_data
          end

          def validation_errors(value)
            klass = Object.const_get(expected_class_name)
            unless value.is_a?(klass)
              build_error(value)
            end
          end

          def error_message(value)
            "#{value} is not an instance of #{expected_class_name}"
          end

          def error_context(value)
            {
              value:,
              expected_class_name:
            }
          end
        end
      end
    end
  end
end
