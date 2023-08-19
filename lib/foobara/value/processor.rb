module Foobara
  module Value
    class Processor
      module Priority
        FIRST = 0
        HIGH = 10
        MEDIUM = 20
        LOW = 30
      end

      class << self
        # NOTE: obviously can't use this convenience method for processors with declaration data
        def instance
          @instance ||= new
        end

        def error_classes
          @error_classes ||= begin
            error_klasses = Util.constant_values(self, extends: Foobara::Error)

            if superclass < Processor
              error_klasses += superclass.error_classes
            end

            error_klasses
          end
        end

        def error_class
          return @error_class if defined?(@error_class)

          unless error_classes.size == 1
            # :nocov:
            raise "Expected exactly one error class to be defined for #{name} but has #{error_classes.size}"
            # :nocov:
          end

          @error_class = error_classes.first
        end

        def symbol
          @symbol ||= name&.demodulize&.gsub(/(Processor|Transformer|Validator)$/, "")&.underscore&.to_sym
        end

        def declaration_data_type
          :duck
        end
      end

      attr_accessor :declaration_data, :declaration_data_given

      def initialize(*args)
        args_count = args.size

        if args_count == 1
          self.declaration_data = args.first
          self.declaration_data_given = true
        elsif args_count != 0
          # :nocov:
          raise ArgumentError, "Expected 0 or 1 arguments containing the #{self.class.name} data"
          # :nocov:
        end
      end

      delegate :error_class,
               :error_classes,
               :symbol,
               :declaration_data_type,
               to: :class

      # TODO: this is a problem or an indicator we need to couple Type and Schema.
      # here we are in the Type namespace but we really need to communicate the error context schemas to the
      # outside world for things like Schema and Command to work well.
      # A solution... a way to map built-in validator errors to schemas a level up in Schema.
      # Not necessary but maybe a good idea just to preserve separation of concerns for longer
      def error_context_schema
        error_class.context_schema
      end

      def error_symbol
        error_class.symbol
      end

      def error_message(value)
        error_class.message(value)
      end

      def error_context(value)
        error_class.context(value)
      end

      def possible_errors
        path = []

        error_classes.map do |error_class|
          [path, error_class.symbol, error_class.context_schema]
        end
      end

      def process_outcome(old_outcome)
        return old_outcome if old_outcome.is_a?(Value::HaltedOutcome)

        process(old_outcome.result).tap do |outcome|
          outcome.add_errors(old_outcome.errors)
        end
      end

      def process!(value)
        outcome = process(value)

        if outcome.success?
          outcome.result
        else
          outcome.raise!
        end
      end

      # A transformer with no declaration data or with declaration data of false is considered to be
      # not applicable. Override this wherever different behavior is needed.
      # TODO: do any transformers really need this _value argument to determine applicability??
      def applicable?(_value)
        always_applicable?
      end

      # This means its applicable regardless of value to transform. Override if different behavior is needed.
      def always_applicable?
        declaration_data
      end

      def declaration_data_given?
        declaration_data_given
      end

      def process(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def error_halts_processing?
        false
      end

      def build_error(
        value = nil,
        error_class: self.error_class,
        symbol: error_class.symbol,
        message: error_message(value),
        context: error_context(value),
        path: error_path,
        **args
      )
        unless error_classes.include?(error_class)
          # :nocov:
          raise "invalid error"
          # :nocov:
        end

        error_class.new(
          path:,
          message:,
          context:,
          symbol:,
          **args
        )
      end

      def error_path
        Array.wrap(attribute_name)
      end

      # TODO: this is a bit problematic. Maybe eliminate this instead of assuming it's generally useful
      def attribute_name
        nil
      end

      # Helps control when it runs in a pipeline
      def priority
        Priority::MEDIUM
      end

      def inspect
        s = super

        if s.size > 400
          "#{s[0..400]}..."
        end
      end

      def method_missing(method, *args, **opts)
        method == symbol ? declaration_data : super
      end

      def respond_to_missing?(method, private = false)
        method == symbol || super
      end
    end
  end
end
