module Foobara
  module Models
    module Types
      class Integer
        class << self
          def symbol
            name.demodulize.downcase.to_sym
          end
        end
      end
    end
  end
end
