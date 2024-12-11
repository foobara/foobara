module Foobara
  module DomainMapperLookups
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

    class AmbiguousDomainMapperError < StandardError
      attr_accessor :candidates, :from, :to

      def initialize(from, to, candidates)
        self.to = to
        self.from = from
        self.candidates = [*candidates].flatten

        super("#{candidates.size} ambiguous candidates found.")
      end
    end

    include Concern

    module ClassMethods
      def lookup_matching_domain_mapper!(from: nil, to: nil, strict: false)
        result = lookup_matching_domain_mapper(from:, to:, strict:)

        result || raise(NoDomainMapperFoundError.new(from, to))
      end

      def lookup_matching_domain_mapper(from: nil, to: nil, strict: false)
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
            lookup_matching_domain_mapper(from: nil, to:)
          elsif to
            lookup_matching_domain_mapper(from:, to: nil)
          end
        end
      end

      def mappers
        @mappers ||= foobara_all_domain_mapper
      end
    end
  end
end
