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

      def name
        (self.class.name || "Anonymous")
      end

      delegate :error_class,
               :error_classes,
               :symbol,
               to: :class

      # Whoa, forgot this existed. Shouldn't we use this more?
      def runner(value)
        self.class::Runner.new(self, value)
      end

      def error_symbol
        error_class.symbol
      end

      # TODO: probably actually better to pass it through to the error class method. Bring that back.
      def error_message(_value)
        error_class.message
      end

      def error_context(_value)
        error_class.context
      end

      def possible_errors
        error_classes.to_h do |error_class|
          # TODO: strange that this is set this way?
          key = ErrorKey.new(symbol: error_class.symbol, category: error_class.category)
          [key.to_s, error_class]
        end
      end

      # A transformer with no declaration data or with declaration data of false is considered to be
      # not applicable. Override this wherever different behavior is needed.
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

      def process_value(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def process_value!(value)
        process_value(value).result!
      end

      def process_outcome(old_outcome)
        return old_outcome if old_outcome.fatal?

        value = old_outcome.result

        return old_outcome unless applicable?(value)

        process_value(value).tap do |outcome|
          outcome.add_errors(old_outcome.errors)
        end
      end

      def process_outcome!(old_outcome)
        process_outcome(old_outcome).result!
      end

      def build_error(
        value = nil,
        error_class: self.error_class,
        symbol: error_class.symbol,
        message: error_message(value),
        context: error_context(value),
        path: error_path,
        **
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
          **
        )
      end

      # TODO: does this make sense to have something called attribute_name here??
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
          # :nocov:
          s = "#{s[0..400]}..."
          # :nocov:
        end

        s
      end

      def method_missing(method, *args, **opts)
        if method == symbol
          declaration_data
        else
          # :nocov:
          super
          # :nocov:
        end
      end

      def respond_to_missing?(method, private = false)
        method == symbol || super
      end
    end
  end
end
