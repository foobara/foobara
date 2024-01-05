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

          # Why is this here in entity/ instead of in model/?
          def possible_errors
            return {} if parent_declaration_data == { type: :entity }

            binding.pry
            if parent_declaration_data.key?(:model_class)
              Object.const_get(parent_declaration_data[:model_class]).possible_errors(mutable: true)
            elsif parent_declaration_data[:type] != :entity
              mutable = parent_declaration_data[:mutable]

              return {} unless mutable

              model_type = type_for_declaration(parent_declaration_data[:type])
              model_class = model_type.target_class
              model_class.possible_errors(mutable:)
            else
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
