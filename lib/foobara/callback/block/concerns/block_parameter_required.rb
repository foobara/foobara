module Foobara
  module Callback
    module Concerns
      module BlockParameterRequired
        private

        def validate_original_block!
          super

          unless takes_block?
            # :nocov:
            raise ArgumentError, "#{type} callback must take a block argument"
            # :nocov:
          end
        end
      end
    end
  end
end
