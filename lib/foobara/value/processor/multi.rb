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

        def processor_names
          processors.map do |processor|
            (processor.class.name || "Anonymous").demodulize
          end
        end

        def error_classes
          normalize_error_classes([*super, *processors.map(&:error_classes).flatten])
        end

        def applicable?(value)
          super || processors.any? { |processor| processor.applicable?(value) }
        end

        # format?
        # maybe [path, symbol, context_type] ?
        # maybe [path, error_class] ?
        def possible_errors
          processors.inject(super) do |possibilities, processor|
            possibilities.merge(processor.possible_errors)
          end
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
