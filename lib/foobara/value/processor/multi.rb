module Foobara
  module Value
    class Processor
      class Multi < Processor
        attr_accessor :processors, :prioritize

        def initialize(*args, processors: [], prioritize: true)
          self.prioritize = prioritize
          self.processors = prioritize ? processors.sort_by(&:priority) : processors
          super(*args)
        end

        def error_classes
          [*super, *processors.map(&:error_classes).flatten]
        end

        def applicable?(value)
          super || processors.any? { |processor| processor.applicable?(value) }
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
          self.processors = [*processors, processor].sort_by(&:priority)
        end

        def process_outcome(_old_outcome)
          raise "subclass responsibility"
        end

        def process(value)
          process_outcome(Outcome.success(value))
        end
      end
    end
  end
end
