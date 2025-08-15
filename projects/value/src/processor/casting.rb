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

        attr_accessor :target_classes

        def initialize(*, casters:, target_classes: nil, **)
          self.target_classes = Util.array(target_classes)

          processors = [
            *does_not_need_cast_processor,
            *casters
          ]

          super(*, processors:, **)
        end

        def needs_cast?(value)
          !does_not_need_cast_processor.applicable?(value)
        end

        def can_cast?(value)
          processors.any? { |processor| processor.applicable?(value) }
        end

        def does_not_need_cast_processor
          return @does_not_need_cast_processor if defined?(@does_not_need_cast_processor)

          errorified_name = target_classes.map do |c|
            if c.name
              c.name
            elsif c.respond_to?(:foobara_name)
              c.foobara_name
            else
              # TODO: test this code path
              # :nocov:
              "Anon"
              # :nocov:
            end
          end.map { |name| name.split("::").last }.sort.join("Or")

          class_name = "NoCastNeededIfIsA#{errorified_name}"

          @does_not_need_cast_processor = if target_classes && !target_classes.empty?
                                            Caster.subclass(
                                              name: class_name,
                                              applicable?: ->(value) {
                                                target_classes.any? { |target_class| value.is_a?(target_class) }
                                              },
                                              applies_message: "be a #{target_classes.map(&:name).join(" or ")}",
                                              cast: ->(value) { value }
                                            ).instance
                                          end
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
