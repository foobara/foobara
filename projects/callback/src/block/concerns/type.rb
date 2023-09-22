module Foobara
  module Callback
    class Block
      module Concerns
        module Type
          include Concern

          module ClassMethods
            def type
              @type ||= Util.non_full_name_underscore(self)&.gsub(/_block$/, "")&.to_sym
            end
          end
        end
      end
    end
  end
end
