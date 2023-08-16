module Foobara
  module Value
    class Processor
      class Multi < Processor
        attr_accessor :processors

        def initialize(*args, processors: [])
          self.processors = processors
          super(*args)
        end

        def error_classes
          [*super, *processors.map(&:error_classes).flatten]
        end

        def applicable?(value)
          processors.any? { |processor| processor.applicable?(value) }
        end

        # format?
        # maybe [path, symbol, context_type] ?
        # maybe [path, error_class] ?
        def possible_errors
          processors.inject(super) do |possibilities, processor|
            possibilities + processor.possible_errors
          end
        end

        def register(processor)
          processors << processor
        end

        def process_outcome(old_outcome)
          raise "subclass responsibility"
        end

        def process(value)
          process_outcome(Outcome.success(value))
        end
      end
    end
  end
end
