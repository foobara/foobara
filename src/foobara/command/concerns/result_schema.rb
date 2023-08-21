module Foobara
  class Command
    module Concerns
      module ResultSchema
        extend ActiveSupport::Concern

        class_methods do
          def result_schema(*args)
            if args.empty?
              @result_schema
            else
              if args.count > 1
                # :nocov:
                raise ArgumentError, "Expected 0 or 1 arguments"
                # :nocov:
              end

              raw_result_schema = args.first

              @result_schema = type_for_declaration(raw_result_schema)
            end
          end

          def raw_result_schema
            result_schema.raw_declaration_data
          end
        end

        delegate :result_schema, :raw_result_schema, to: :class
      end
    end
  end
end
