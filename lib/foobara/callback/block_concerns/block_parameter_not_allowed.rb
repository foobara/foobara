module Foobara
  module Callback
    module BlockParameterNotAllowed
      private

      def validate_block_arguments_of_original_block!
        if takes_block?
          raise "#{type} callback is not allowed to accept a block"
        end
      end
    end
  end
end
