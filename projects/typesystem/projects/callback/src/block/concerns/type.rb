require "foobara/concerns"

module Foobara
  module Callback
    class Block
      module Concerns
        module Type
          include Concern

          module ClassMethods
            # TODO: consider renaming this to symbol? Could be confused with Foobara::Type concept
            # Returns things like :before, :after, :around, :error to indicate what type of callback it is
            def type
              @type ||= Util.non_full_name_underscore(self)&.gsub(/_block$/, "")&.to_sym
            end
          end
        end
      end
    end
  end
end
