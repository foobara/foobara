module Foobara
  module CommandPatternImplementation
    module Concerns
      module Inputs
        class UnexpectedInputValidationError < StandardError; end

        include Concern

        module ClassMethods
          def inputs_association_paths
            return @inputs_association_paths if defined?(@inputs_association_paths)

            @inputs_association_paths = if inputs_type.nil?
                                          nil
                                        else
                                          keys = Entity.construct_associations(inputs_type).keys

                                          if keys.empty?
                                            nil
                                          else
                                            keys.map do |key|
                                              DataPath.new(key)
                                            end
                                          end
                                        end
          end
        end

        attr_reader :inputs, :raw_inputs

        def initialize(inputs = {})
          @raw_inputs = inputs
          super()
        end

        def method_missing(method_name, *args, &)
          if respond_to_missing_for_inputs?(method_name)
            inputs[method_name]
          else
            # :nocov:
            super
            # :nocov:
          end
        end

        def respond_to_missing?(method_name, private = false)
          respond_to_missing_for_inputs?(method_name, private) || super
        end

        def respond_to_missing_for_inputs?(method_name, _private = false)
          inputs_type&.element_types&.key?(method_name)
        end

        def cast_and_validate_inputs
          if inputs_type.nil? && (raw_inputs.nil? || raw_inputs.empty?)
            @inputs = {}
            return
          end

          outcome = inputs_type.runner(raw_inputs).process_value

          if outcome.success?
            @inputs = outcome.result
          else
            outcome.errors.each do |error|
              if error.is_a?(Value::DataError)
                add_input_error(error)
              else
                # :nocov:
                raise UnexpectedInputValidationError, "Unexpected input validation error: #{error}"
                # :nocov:
              end
            end
          end

          if outcome.success?
            @inputs = outcome.result
          end
        end
      end
    end
  end
end
