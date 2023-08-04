module Foobara
  module Value
    class Processor
      class << self
        attr_writer :metadata

        def error_class
          Error
        end

        def metadata
          @metadata ||= {}
        end

        def class_from(**args, &from_proc)
          metadata = args[:metadata] || {}

          klass = Class.new(self) do
            define_method primary_proc_method do |*call_args, **call_opts, &block|
              from_proc.call(*call_args, **call_opts, &block)
            end
          end

          klass.metadata = klass.metadata.merge(metadata)

          klass
        end

        def from(**args, &)
          # TODO: validate args
          klass = class_from(**args, &)

          if args.key?(:data)
            klass.new(args[:data])
          else
            klass.new
          end
        end

        def primary_proc_method
          :call
        end
      end

      attr_reader :data, :data_was_given

      def initialize(*args)
        case args.size
        when 0
          @data_was_given = false
        when 1
          @data_was_given = true
          @data = args.first
        else
          raise ArgumentError, "Expected 0 or 1 arguments containing the data"
        end
      end

      delegate :error_class, to: :class

      def data_given?
        data_was_given
      end

      def call(_value)
        raise "subclass responsibility"
      end
    end
  end
end
