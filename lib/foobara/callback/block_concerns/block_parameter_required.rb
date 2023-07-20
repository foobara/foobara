module Foobara
  module Callback
    module BlockParameterRequired
      private

      def validate_block_arguments_of_original_block!
        unless takes_block?
          raise "#{type} callback must take a block argument to receive the do_it block"
        end
      end
    end
  end
end
