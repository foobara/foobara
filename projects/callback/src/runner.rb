module Foobara
  module Callback
    class Runner
      class UnexpectedErrorWhileRunningCallback < StandardError
        attr_accessor :callback_data

        def initialize(callback_data, error)
          super(error.message)

          self.callback_data = callback_data
        end
      end

      attr_accessor :callback_set, :error
      attr_writer :callback_data

      def initialize(callback_set)
        self.callback_set = callback_set
      end

      def has_callback_data?
        defined?(@callback_data)
      end

      def callback_data(*args, **opts)
        return @callback_data if args.empty? && opts.empty?

        self.callback_data = Util.args_and_opts_to_opts(args, opts)

        self
      end

      def run(&do_it)
        if block_given?
          callback_set.each_before do |callback|
            run_callback(callback)
          end

          around_callback = callback_set.around.inject(do_it) do |nested_proc, callback|
            proc do
              run_callback(callback, &nested_proc)
            end
          end

          run_callback(around_callback)
        else
          # TODO: raise better errors
          if callback_set.has_before_callbacks?
            # :nocov:
            raise
            # :nocov:
          end
          if callback_set.has_around_callbacks?
            # :nocov:
            raise
            # :nocov:
          end
        end

        callback_set.each_after do |callback|
          run_callback(callback)
        end
      rescue => real_error
        begin
          raise UnexpectedErrorWhileRunningCallback.new(callback_data, real_error)
          # this non-sense is just to set the Error#cause properly
        rescue UnexpectedErrorWhileRunningCallback => e
          self.error = e

          callback_set.each_error do |callback|
            run_callback(callback)
          end
        end

        raise
      end

      def run_callback(callback, &)
        if error
          callback.call(error)
        elsif has_callback_data?
          callback.call(callback_data, &)
        else
          callback.call(&)
        end
      end
    end
  end
end
