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
              nil
            when 1
              processors.first
            else
              Value::Processor::Pipeline.new(processors:)
            end
          end

          def desugarizers
            @desugarizers ||= []

            if superclass == Object
              @desugarizers
            else
              @desugarizers + superclass.desugarizers
            end
          end
        end
      end
    end
  end
end
