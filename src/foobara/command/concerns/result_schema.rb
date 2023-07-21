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
              raw_result_schema = args.first
              @result_schema = Foobara::Model::Schema.for(raw_result_schema)
            end
          end

          def raw_result_schema
            result_schema.raw_schema
          end
        end

        delegate :result_schema, :raw_result_schema, to: :class
      end
    end
  end
end
