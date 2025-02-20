module Foobara
  class Command < Service
    module Concerns
      module Description
        include Concern

        module ClassMethods
          def description(*args)
            if args.empty?
              @description
            elsif args.size == 1
              @description = args.first
            else
              # :nocov:
              raise ArgumentError, "wrong number of arguments (#{args.size} for 0 or 1)"
              # :nocov:
            end
          end
        end
      end
    end
  end
end
