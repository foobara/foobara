module Foobara
  class Entity < Model
    class NotFoundError < Foobara::RuntimeError
      class << self
        def not_found_error_class_name(data_path)
          error_class_name = data_path.path.map { |part| part == :"#" ? "Collection" : Util.classify(part) }.join
          "#{error_class_name}NotFoundError"
        end

        def subclass(mod, entity_class, data_path)
          error_class_name = not_found_error_class_name(data_path)

          # TODO: how would we avoid name collisions here??
          Util.make_class("#{mod.name}::#{error_class_name}", self) do
            # TODO: use Concern to change these into attr_accessor instead
            singleton_class.define_method :data_path do
              data_path
            end

            singleton_class.define_method :entity_class do
              entity_class
            end

            singleton_class.define_method :context_type_declaration do
              {
                entity_class: :string, # TODO: we don't have a way to specify an exact value for a type
                primary_key: entity_class.primary_key_type.declaration_data,
                data_path: :string # TODO: we don't have a way to specify an exact value for a type
              }
            end
          end
        end

        def context_type_declaration
          {
            entity_class: :string, # TODO: we don't have a way to specify an exact value for a type
            primary_key: :duck, # TODO: probably should be integer or string but no union types yet
            data_path: :string # TODO: we don't have a way to specify an exact value for a type
          }
        end
      end

      attr_accessor :data_path, :entity_class, :primary_key

      foobara_delegate :primary_key_attribute, :full_entity_name, to: :entity_class

      def initialize(primary_key, entity_class: self.class.entity_class, data_path: self.class.data_path)
        self.primary_key = primary_key
        self.entity_class = entity_class
        self.data_path = data_path

        super(context:, message:)
      end

      def context
        {
          entity_class: full_entity_name,
          primary_key:,
          data_path: data_path.to_s
        }
      end

      def message
        "Could not find #{entity_class} with #{primary_key_attribute} of #{primary_key}"
      end
    end
  end
end
