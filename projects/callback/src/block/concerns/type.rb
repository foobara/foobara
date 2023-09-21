module Foobara
  module Callback
    class Block
      module Concerns
        module Type
          include Concern

          module ClassMethods
            def type
              @type ||= name.demodulize.gsub(/Block$/, "").underscore.to_sym
            end
          end
        end
      end
    end
  end
end
