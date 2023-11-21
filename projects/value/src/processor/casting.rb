Foobara.require_file("value", "data_error")

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
          def manifest
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

        attr_accessor :casters, :target_classes

        def initialize(*args, casters:, target_classes: nil)
          self.target_classes = Util.array(target_classes)
          self.casters = casters
          super(*args)
        end

        def processors
          [
            does_not_need_cast_processor,
            *casters
          ].compact
        end

        def needs_cast?(value)
          !does_not_need_cast_processor.applicable?(value)
        end

        def can_cast?(value)
          processors.any? { |processor| processor.applicable?(value) }
        end

        def does_not_need_cast_processor
          return @does_not_need_cast_processor if defined?(@does_not_need_cast_processor)

          @does_not_need_cast_processor = if target_classes && !target_classes.empty?
                                            Caster.subclass(
                                              name: ["no_cast_needed_if_is_a", *target_classes.map(&:name)].join(";"),
                                              applicable?: ->(value) {
                                                target_classes.any? { |target_class| value.is_a?(target_class) }
                                              },
                                              applies_message: "be a #{target_classes.map(&:name).join(" or ")}",
                                              cast: ->(value) { value }
                                            ).instance
                                          end
        end

        def error_message(value)
          type = declaration_data[:cast_to][:type].to_s
          article = type =~ /^[aeiouy]/i ? "an" : "a"

          "Cannot cast #{value.inspect} to #{article} #{type}. Expected it to #{applies_message}"
        end

        def applies_message
          Util.to_or_sentence(processors.map(&:applies_message).flatten)
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
            raise "Matched too many casters for #{args.inspect} with #{opts.inspect}"
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
