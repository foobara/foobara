module Foobara
  class Model
    class Entity
      module Concerns
        module Schema
          extend ActiveSupport::Concern

          class_methods do
            def schema(*args)
              return @schema if args.empty?

              @schema = Foobara::Model::Schema::Attributes.new(args.first)
              type = schema.type

              unless type == :attributes
                raise InvalidSchema, "Expected schema to be for attributes but was instead for #{type}"
              end

              schema.validate!

              schema
            end

            def primary_key(*args)
              return @primary_key if args.empty?

              primary_key_attribute_name = args.first

              unless schema.valid_attribute_name?(primary_key_attribute_name)
                raise "Invalid primary key name, must be one of #{schema.valid_attribute_names}"
              end
            end
          end
        end
      end
    end
  end
end
