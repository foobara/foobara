module Foobara
  module Callback
    class Runner
      attr_accessor :callback_set
      attr_writer :callback_data

      def initialize(callback_set)
        self.callback_set = callback_set
      end

      def callback_data(*args, **opts)
        return @callback_data if args.blank? && opts.blank?

        self.callback_data = if args.empty?
                               opts
                             else
                               raise "Was not expecting more than one argument" if args.length > 1

                               arg = args.first
                               if opts.present?
                                 raise "Not sure how to combine #{arg} and #{opts}" unless arg.is_a?(Hash)

                                 arg.merge(opts)
                               else
                                 arg
                               end
                             end

        self
      end

      def run(&do_it)
        if block_given?
          callback_set.each_before do |callback|
            run_callback(callback)
          end

          begin
            around_callback = callback_set.around.inject(do_it) do |nested_proc, callback|
              proc do
                run_callback(callback, extra_args: [nested_proc])
              end
            end

            run_callback(around_callback)
          rescue => e
            callback_set.each_error do |callback|
              run_callback(callback, extra_args: [e])
            end

            raise
          end
        else
          # TODO: raise better errors
          raise if callback_set.has_before_callbacks?
          raise if callback_set.has_around_callbacks?
        end

        callback_set.each_after do |callback|
          run_callback(callback)
        end
      end

      def run_callback(callback, extra_args: [])
        if callback_data.is_a?(Hash) && callback.parameters.first&.first == :keyreq
          callback.call(*extra_args, **callback_data)
        else
          callback.call(*extra_args, callback_data)
        end
      end
    end
  end
end
