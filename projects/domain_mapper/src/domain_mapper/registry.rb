module Foobara
  class DomainMapper
    class NoDomainMapperFoundError < StandardError
      attr_accessor :value, :from, :to, :has_value

      def initialize(from, to, **opts)
        valid_keys = [:value]
        invalid_keys = opts.keys - [:value]

        if invalid_keys.any?
          # :nocov:
          raise ArgumentError, "Invalid keys: #{invalid_keys.join(", ")}. expected one of: #{valid_keys.join(", ")}"
          # :nocov:
        end

        if opts.key?(:value)
          self.has_value = true
          self.value = opts[:value]
        end

        self.from = from
        self.to = to

        super("No domain mapper found for #{value}. from: #{from}. to: #{to}.")
      end
    end

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

      def lookup!(from: nil, to: nil, strict: false)
        result = lookup(from:, to:, strict:)

        result || raise(NoDomainMapperFoundError.new(from, to))
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
