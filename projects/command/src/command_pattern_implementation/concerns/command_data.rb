module Foobara
  module CommandPatternImplementation
    module Concerns
      module CommandData
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

          def is_query
            @is_query = true
          end

          # rubocop:disable Naming/MemoizedInstanceVariableName
          def query?
            return @is_query if defined?(@is_query)

            @is_query = if superclass.respond_to?(:query?)
                          superclass.query?
                        end
          end
          # rubocop:enable Naming/MemoizedInstanceVariableName
        end
      end
    end
  end
end
