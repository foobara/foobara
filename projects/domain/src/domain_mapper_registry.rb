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
        mappers[mapper.from_type] = if mappers.key?(mapper.from_type)
                                      [*mappers[mapper.from_type], mapper]
                                    else
                                      mapper
                                    end
      end

      def lookup(from_type: nil, to_type: nil)
        if from_type.nil?
          if mappers.size == 1
            candidates = mappers.values.first

            if candidates.is_a?(::Array)
              if candidates.size == 1
                candidates.first
              else
                raise AmbiguousDomainMapperError.new(from_type, to_type, candidates)
              end
            else
              candidates
            end
          elsif mappers.size > 1
            raise AmbiguousDomainMapperError.new(from_type, to_type, mappers.values)
          end
        else
          candidates = mappers[from_type]

          if candidates.is_a?(::Array)
            if candidates.size == 1
              candidates.first
            else
              if to_type.nil?
                raise AmbiguousDomainMapperError.new(from_type, to_type, candidates)
              end

              candidates.find do |candidate|
                candidate.to_type == to_type
              end
            end
          else
            candidates
          end
        end
      end

      def mappers
        @mappers ||= {}
      end
    end
  end
end
