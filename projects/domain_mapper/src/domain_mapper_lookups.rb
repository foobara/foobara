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
      def new_mapper_registered!
        if defined?(@mappers) && !@mappers.empty?
          remove_instance_variable("@mappers")
        end
      end

      def lookup_matching_domain_mapper!(from: nil, to: nil, strict: false, criteria: nil)
        result = lookup_matching_domain_mapper(from:, to:, strict:, criteria:)

        result || raise(NoDomainMapperFoundError.new(from, to))
      end

      def lookup_matching_domain_mapper(from: nil, to: nil, strict: false, criteria: nil)
        candidates = mappers.select do |mapper|
          if criteria
            next unless criteria.call(mapper)
          end

          mapper.applicable?(from, to)
        end

        if candidates.size > 1
          best = []
          best_score = 0

          candidates.each do |mapper|
            score = mapper.applicable_score(from, to)

            if score > best_score
              best = [mapper]
              best_score = score
            elsif score == best_score
              best << mapper
            end
          end

          if best.size > 1
            raise AmbiguousDomainMapperError.new(from, to, candidates)
          else
            candidates = best
          end
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
