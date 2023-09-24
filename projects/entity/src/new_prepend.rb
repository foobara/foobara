module Foobara
  class Entity < Model
    module NewPreprend
      def new(*args, validate: false, outside_transaction: false, **opts)
        arg = Util.args_and_opts_to_opts(args, opts)

        if arg.is_a?(::Hash)
          super(arg, validate:, outside_transaction:)
        elsif outside_transaction
          super(arg, outside_transaction: true)
        else
          current_transaction_table.find_tracked(arg) || super(arg)
        end
      end
    end
  end
end
