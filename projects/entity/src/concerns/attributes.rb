module Foobara
  class Entity < Model
    module Concerns
      module Attributes
        class UnexpectedPrimaryKeyChangeError < StandardError; end

        include Concern

        def write_attribute_without_callbacks(attribute_name, value)
          without_callbacks do
            write_attribute(attribute_name, value)
          end
        end

        def write_attribute(attribute_name, value)
          verify_transaction_is_open!
          verify_not_hard_deleted!

          with_changed_attribute_callbacks(attribute_name) do
            load_if_necessary!(attribute_name)

            attribute_name = attribute_name.to_sym

            if attribute_name == primary_key_attribute
              if value.nil?
                # :nocov:
                raise "Primary key cannot be set to a blank value"
                # :nocov:
              end

              if value.is_a?(::String) && value.empty?
                # :nocov:
                raise "Primary key cannot be set to a blank value"
                # :nocov:
              end

              if value.is_a?(::Symbol) && value.to_s.empty?
                # :nocov:
                raise "Primary key cannot be set to a blank value"
                # :nocov:
              end

              write_attribute!(attribute_name, value)
            else
              attribute_name = attribute_name.to_sym
              outcome = cast_attribute(attribute_name, value)
              attributes[attribute_name] = outcome.success? ? outcome.result : value
            end
          end
        end

        def write_attribute_without_callbacks!(attribute_name, value)
          without_callbacks do
            write_attribute!(attribute_name, value)
          end
        end

        def write_attribute!(attribute_name, value)
          verify_transaction_is_open!
          verify_not_hard_deleted!

          with_changed_attribute_callbacks(attribute_name) do
            load_if_necessary!(attribute_name)

            attribute_name = attribute_name.to_sym

            if attribute_name == primary_key_attribute && primary_key
              outcome = cast_attribute(attribute_name, value)

              if outcome.success?
                value = outcome.result
              end

              if value != primary_key
                raise UnexpectedPrimaryKeyChangeError,
                      "Primary key already set to #{primary_key}. Can't change to #{value}. " \
                      "Use attributes[:#{attribute_name}] = #{value.inspect} " \
                      "instead if you really want to change the primary key."
              end
            end

            attribute_name = attribute_name.to_sym
            attributes[attribute_name] = cast_attribute!(attribute_name, value)
          end
        end

        def write_attributes_without_callbacks(attributes)
          without_callbacks do
            write_attributes(attributes)
          end
        end

        def write_attributes(attributes)
          verify_transaction_is_open!
          verify_not_hard_deleted!

          with_changed_attribute_callbacks(attributes.keys) do
            load_if_necessary!(attributes)

            attributes.each_pair do |attribute_name, value|
              write_attribute_without_callbacks(attribute_name, value)
            end
          end
        end

        def read_attribute(attribute_name)
          load_if_necessary!(attribute_name)
          super
        end

        def read_attribute!(attribute_name)
          load_if_necessary!(attribute_name)
          super
        end

        def with_changed_attribute_callbacks(attribute_names)
          # TODO: clean up methods to use this flag instead of calling each other
          if @callbacks_disabled
            yield
            return
          end

          attribute_names = Util.array(attribute_names)

          old_is_dirty = dirty? # TODO: don't bother with this check unless there are relevant callbacks
          old_is_valid = valid? # TODO: don't bother with this check unless there are relevant callbacks

          old_values = attribute_names.map { |attribute_name| read_attribute(attribute_name) }

          yield

          new_values = attribute_names.map { |attribute_name| read_attribute(attribute_name) }

          attribute_changed = false

          old_values.each.with_index do |old_value, index|
            new_value = new_values[index]

            if new_value != old_value
              attribute_changed = true
              fire(:attribute_changed, attribute_name: attribute_names[index], old_value:, new_value:)
            end
          end

          if attribute_changed
            new_is_dirty = dirty?

            if old_is_dirty != new_is_dirty
              old_is_dirty ? fire(:undirtied) : fire(:dirtied)
            end

            new_is_valid = valid?

            if old_is_valid != new_is_valid
              # TODO: don't bother with this check unless there are relevant callbacks
              new_is_valid ? fire(:uninvalidated) : fire(:invalidated)
            end
          end
        end
      end
    end
  end
end
