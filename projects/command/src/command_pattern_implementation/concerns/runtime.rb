module Foobara
  module CommandPatternImplementation
    module Concerns
      module Runtime
        include Concern

        class CannotHaltWithoutAddingErrors < StandardError; end
        class Halt < StandardError; end

        class NotFoundError < Foobara::DataError
          context do
            entity_class :string, :required
            criteria :duck
          end
        end

        module ClassMethods
          def run(...)
            new(...).run
          end

          def run!(...)
            new(...).run!
          end
        end

        attr_reader :outcome, :exception
        attr_accessor :raw_result

        def run!
          run.result!
        end

        def run
          Foobara::Namespace.use self.class do
            invoke_with_callbacks_and_transition(:open_transaction)

            invoke_with_callbacks_and_transition_in_transaction([
                                                                  :cast_and_validate_inputs,
                                                                  :load_records,
                                                                  :validate_records,
                                                                  :validate,
                                                                  :run_execute,
                                                                  :commit_transaction
                                                                ])

            invoke_with_callbacks_and_transition(:succeed)
          end

          @outcome
        rescue Halt
          rollback_transaction

          return outcome if state_machine.currently_errored?

          if error_collection.empty?
            # :nocov:
            raise CannotHaltWithoutAddingErrors, "Cannot halt without adding errors first. " \
                                                 "Either add errors or use error! transition instead."
            # :nocov:
          end

          state_machine.fail!

          @outcome = Outcome.errors(error_collection)
        rescue => e
          @exception = e
          rollback_transaction
          state_machine.error!
          raise
        end

        def success?
          outcome&.success?
        end

        def halt!
          raise Halt
        end

        private

        def run_execute
          self.raw_result = execute
          result = process_result_using_result_type(raw_result)
          @outcome = Outcome.success(result)
        end

        def execute
        end

        def succeed
          # noop but for now helpful for carrying out state transition
        end

        def validate_records
          self.class.inputs_association_paths&.each do |data_path|
            if data_path.last == :"#"
              records = data_path.values_at(@inputs)

              records.each.with_index do |record, index|
                if record&.persisted? && !record.loaded?
                  begin
                    record.class.load(record)
                  rescue Foobara::Entity::NotFoundError => e
                    add_input_error(
                      [*data_path.path[..-2], index],
                      CommandPatternImplementation::NotFoundError,
                      criteria: e.criteria,
                      entity_class: record.class.model_type.scoped_full_name
                    )
                  end
                end
              end
            else
              record = data_path.value_at(@inputs)

              if record&.persisted? && !record.loaded?
                begin
                  record.class.load(record)
                rescue Foobara::Entity::NotFoundError => e
                  add_input_error(
                    data_path.to_s,
                    CommandPatternImplementation::NotFoundError,
                    criteria: e.criteria,
                    entity_class: record.class.model_type.scoped_full_name
                  )
                end
              end
            end
          end
        end

        def validate
          # can override if desired, default is a no-op
        end

        def invoke_with_callbacks_and_transition_in_transaction(transition_or_transitions)
          Persistence::EntityBase.using_transactions(transactions) do
            invoke_with_callbacks_and_transition(transition_or_transitions)
          end
        end

        def invoke_with_callbacks_and_transition(transition_or_transitions)
          result = nil

          if transition_or_transitions.is_a?(Array)
            transition_or_transitions.each do |transition|
              result = invoke_with_callbacks_and_transition(transition)
            end
          else
            transition = transition_or_transitions

            state_machine.perform_transition!(transition) do
              result = send(transition)
              halt! if has_errors?
            end
          end

          result
        end
      end
    end
  end
end
