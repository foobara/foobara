module Foobara
  module Callback
    module Concerns
      module BlockParameterRequired
        private

        def validate_original_block!
          super

          unless takes_block?
            raise "#{type} callback must take a block argument"
          end
        end
      end
    end
  end
end
