Foobara.require_project_file("value", "data_error")

module Foobara
  module Value
    class Processor
      # TODO: at least move this up to Types though that doesn't solve the issue
      class Casting < Selection
        class CannotCastError < DataError
          class << self
            def fatal?
              true
            end
          end

          def message
            if path.empty?
              super
            else
              "At #{path.join(".")}: #{super}"
            end
          end
        end

        class << self
          def foobara_manifest
            # :nocov:
            super.merge(processor_type: :casting)
            # :nocov:
          end

          def error_classes
            [CannotCastError]
          end

          def requires_declaration_data?
            true
          end
        end

        attr_accessor :target_classes, :cast_even_if_instance_of_target_type

        def initialize(*, casters:, target_classes: nil, cast_even_if_instance_of_target_type: nil, **)
          self.target_classes = Util.array(target_classes)

          if cast_even_if_instance_of_target_type
            self.cast_even_if_instance_of_target_type = true
          end

          super(*, processors: casters, **)
        end

        def process_value(value)
          if cast_even_if_instance_of_target_type || needs_cast?(value)
            super
          else
            Outcome.success(value)
          end
        end

        def needs_cast?(value)
          target_classes.none? { |klass| value.is_a?(klass) }
        end

        def can_cast?(value)
          processors.any? { |processor| processor.applicable?(value) }
        end

        def error_message(value)
          type = declaration_data[:cast_to]

          if type.is_a?(::Hash)
            type = type[:type]
          end

          article = type.to_s =~ /^[aeiouy]/i ? "an" : "a"

          "Cannot cast #{value.inspect} to #{article} #{type}. Expected it to #{applies_message}"
        end

        def applies_message
          Util.to_or_sentence(
            [
              "be a #{target_classes.map(&:name).join(" or ")}",
              *processors.map(&:applies_message).flatten
            ]
          )
        end

        def error_context(value)
          {
            cast_to:,
            value:
          }
        end

        def build_error(*args, **opts)
          error_class = opts[:error_class]

          if error_class == NoApplicableProcessorError
            build_error(*args)
          elsif error_class == MoreThanOneApplicableProcessorError
            # :nocov:
            raise "Matched too many casters for #{args.map(&:inspect).join(",")} with #{opts.inspect}"
            # :nocov:
          else
            super
          end
        end

        def cast_to
          # TODO: isn't there a way to declare declaration_data_type so we don't have to validate here??
          unless declaration_data.key?(:cast_to)
            # :nocov:
            raise "Missing cast_to"
            # :nocov:
          end

          declaration_data[:cast_to]
        end
      end
    end
  end
end
