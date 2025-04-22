module Foobara
  class Entity < DetachedEntity
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
                criteria: :duck, # TODO: find_by attributes unioned with primary key
                data_path: :string # TODO: we don't have a way to specify an exact value for a type
              }
            end
          end
        end

        def for(criteria, entity_class: self.entity_class, data_path: self.data_path || "")
          message = "Could not find #{entity_class} for #{criteria}"
          context = {
            entity_class: entity_class.full_entity_name,
            criteria:,
            data_path: data_path.to_s
          }

          new(context:, message:)
        end

        def data_path
          nil
        end
      end

      context do
        entity_class :string # TODO: we don't have a way to specify an exact value for a type
        criteria :duck # TODO: probably should be integer or string but no union types yet
        data_path :string # TODO: we don't have a way to specify an exact value for a type
      end

      foobara_delegate :primary_key_attribute, :full_entity_name, to: :entity_class

      def criteria
        context[:criteria]
      end

      def data_path
        context[:data_path]
      end

      def entity_class
        context[:entity_class]
      end
    end
  end
end
