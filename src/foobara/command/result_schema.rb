module Foobara
  class Command
    module ResultSchema
      extend ActiveSupport::Concern

      class_methods do
        def result_schema(*args)
          if args.empty?
            @result_schema
          else
            raw_result_schema = args.first
            # TODO: make sure result schema is attributes
            @result_schema = Foobara::Models::Schema.new(raw_result_schema)
          end
        end

        def raw_result_schema
          result_schema.raw_schema
        end
      end
    end

    delegate :result_schema, :raw_result_schema, to: :class
  end
end
