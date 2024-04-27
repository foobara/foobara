module Foobara
  class DomainMapper
    class Registry
      class AmbiguousDomainMapperError < StandardError
        attr_accessor :candidates, :from, :to

        def initialize(from, to, candidates)
          self.to = to
          self.from = from
          self.candidates = [*candidates].flatten

          super("#{candidates.size} ambiguous candidates found.")
        end
      end

      def register(mapper)
        mappers << mapper
      end

      def lookup(from: nil, to: nil, strict: false)
        candidates = mappers.select do |mapper|
          mapper.applicable?(from, to)
        end

        if candidates.size > 1
          raise AmbiguousDomainMapperError.new(from, to, candidates)
        end

        value = candidates.first

        return value if value

        unless strict
          if from
            lookup(from: nil, to:)
          elsif to
            lookup(from:, to: nil)
          end
        end
      end

      def mappers
        @mappers ||= []
      end
    end
  end
end
