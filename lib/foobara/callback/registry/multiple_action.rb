module Foobara
  module Callback
    module Registry
      class MultipleAction < Base
        attr_accessor :callback_sets, :possible_actions

        class InvalidAction < StandardError; end

        def initialize(*possible_actions)
          super()

          self.callback_sets = {}

          possible_actions = normalize_actions(possible_actions, false)

          self.possible_actions = possible_actions.map(&:to_s).sort.map(&:to_sym)
        end

        def runner(*actions)
          super(*normalize_actions(actions))
        end

        def before(*actions, &)
          super(*normalize_actions(actions), &)
        end

        def after(*actions, &)
          super(*normalize_actions(actions), &)
        end

        def around(*actions, &)
          super(*normalize_actions(actions), &)
        end

        def error(*actions, &)
          super(*normalize_actions(actions), &)
        end

        def specific_callback_set_for(*actions)
          action = normalize_action(actions)

          validate_action!(action)
          callback_sets[action] ||= Callback::Set.new
        end

        def unioned_callback_set_for(*actions)
          action = normalize_action(actions)

          if action.nil?
            callback_sets.values.reduce(:|) || Callback::Set.new
          else
            set = specific_callback_set_for(nil)
            action ? set | specific_callback_set_for(action) : set
          end
        end

        private

        def validate_action!(action)
          if !action.nil? && !possible_actions.include?(action)
            raise InvalidAction,
                  "Invalid action #{action.inspect} expected nil or one of #{possible_actions}"
          end
        end

        def validate_actions!(actions)
          actions.each { |action| validate_action!(action) }
        end

        def normalize_action(actions)
          case actions.size
          when 0
            nil
          when 1
            action = actions.first
            validate_action!(action)
            action
          else
            # :nocov:
            raise ArgumentError, "Can either pass an action or not but can't pass multiple"
            # :nocov:
          end
        end

        def normalize_actions(actions, validate = true)
          first = actions.first

          if first.is_a?(Array)
            if actions.size == 1
              normalize_actions(first, validate)
            else
              raise ArgumentError, "Not expecting an array of arrays, expected an array of actions"
            end
          elsif actions.empty?
            [nil]
          else
            if validate
              validate_actions!(actions)
            end

            actions
          end
        end
      end
    end
  end
end
