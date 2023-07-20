module Foobara
  module Callback
    module Concerns
      module BlockParameterNotAllowed
        private

        def validate_original_block!
          super

          if takes_block?
            raise "#{type} callback is not allowed to accept a block"
          end
        end
      end
    end
  end
end
