module Foobara
  module BuiltinTypes
    module Entity
      module Validators
        class CreatedInValidState < TypeDeclarations::Processor
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def applicable?(record)
            record.created? || record.built?
          end

          def process_value(record)
            Outcome.new(result: record, errors: record.validation_errors)
          end

          def possible_errors
            return {} if parent_declaration_data == { type: :entity }

            model_class_name = parent_declaration_data[:model_class]

            if model_class_name
              binding.pry
              Object.const_get(model_class_name).possible_errors
            else
              binding.pry
              # :nocov:
              raise "Missing :model_class in parent_declaration_data for #{parent_declaration_data}"
              # :nocov:
            end
          end
        end
      end
    end
  end
end
