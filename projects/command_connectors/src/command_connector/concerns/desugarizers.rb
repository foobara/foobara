module Foobara
  class CommandConnector
    module Concerns
      module Desugarizers
        include Concern

        module ClassMethods
          def add_desugarizer(desugarizer)
            if desugarizer.is_a?(::Class)
              desugarizer = desugarizer.new
            end

            desugarizers << desugarizer
            remove_instance_variable("@desugarizer") if defined?(@desugarizer)
          end

          def desugarizer
            return @desugarizer if defined?(@desugarizer)

            processors = desugarizers

            case processors.size
            when 0
              # TODO: test this code path by removing all desugarizers in a spec.
              # simplecov:disable
              nil
              # simplecov:enable
            when 1
              # TODO: test this code path by removing all desugarizers in a spec.
              # simplecov:disable
              processors[0]
              # simplecov:enable
            else
              Value::Processor::Pipeline.new(processors:)
            end
          end

          def desugarizers
            return @desugarizers if defined?(@desugarizers)

            @desugarizers = if superclass == Object
                              []
                            else
                              superclass.desugarizers.dup
                            end
          end
        end
      end
    end
  end
end
