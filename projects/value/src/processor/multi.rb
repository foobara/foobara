module Foobara
  module Value
    class Processor
      class Multi < Processor
        attr_accessor :processors, :prioritize

        class << self
          def requires_declaration_data?
            false
          end
        end

        def initialize(*args, processors: [], prioritize: true)
          self.prioritize = prioritize
          self.processors = prioritize ? processors.sort_by(&:priority) : processors
          super(*args)
        end

        def processor_names
          processors.map(&:name)
        end

        def error_classes
          normalize_error_classes([*super, *processors.map(&:error_classes).flatten])
        end

        def applicable?(value)
          super || processors.any? { |processor| processor.applicable?(value) }
        end

        def possible_errors
          h = super.to_h do |possible_error|
            [possible_error.key.to_s, possible_error]
          end

          processors.map(&:possible_errors).flatten.each do |possible_error|
            h[possible_error.key.to_s] = possible_error
          end

          # TODO: change this back to a hash
          h.values
        end

        def register(processor)
          self.processors = [*processors, processor].sort_by(&:priority)
        end

        private

        def normalize_error_classes(error_classes)
          cannot_cast_errors, others = error_classes.partition do |c|
            # TODO: some kind of dependency issue here??
            c == Foobara::Value::Processor::Casting::CannotCastError
          end

          [*cannot_cast_errors.uniq, *others]
        end
      end
    end
  end
end
