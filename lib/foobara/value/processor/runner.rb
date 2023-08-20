module Foobara
  module Value
    class Processor
      class Runner
        class << self
          def runner_methods(*method_names)
            method_names.each do |method_name|
              instance_variable = :"@#{method_name}"

              define_method method_name do
                if instance_variables.include?(instance_variable)
                  instance_variable_get(instance_variable)
                else
                  instance_variable_set(instance_variable, processor.send(method_name, value))
                end
              end
            end
          end
        end

        attr_accessor :value, :processor

        def initialize(processor, value)
          self.processor = processor
          self.value = value
        end

        # TODO: feels like caster should be moved to Types
        runner_methods :error_message, :error_context, :process, :process!, :applicable?
      end
    end
  end
end
