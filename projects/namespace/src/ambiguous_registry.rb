module Foobara
  class Namespace
    class AmbiguousRegistry < BaseRegistry
      class AmbiguousLookupError < StandardError; end

      def foobara_registry
        @foobara_registry ||= {}
      end

      def register(scoped)
        short_name = scoped.scoped_short_name
        foobara_registry[short_name] ||= []
        foobara_registry[short_name] |= [scoped]
      end

      def lookup(path, filter = nil)
        *prefix, short_name = path
        matches = apply_filter(foobara_registry[short_name], filter)

        if matches && !matches.empty?
          _best_match(prefix, matches, path)
        end
      end

      private

      def _best_match(prefix, matches, path)
        candidates = nil
        candidate_hits = -1
        candidate_misses = 1

        matches.each do |match|
          hits, misses = _score(prefix, match)

          if hits
            if hits == candidate_hits
              if misses == candidate_misses
                candidates << match
              elsif misses > candidate_misses
                candidates = [match]
                candidate_misses = misses
                candidate_hits = hits
              end
            elsif hits > candidate_hits
              candidates = [match]
              candidate_misses = misses
              candidate_hits = hits
            end
          end
        end

        if candidates
          if candidates.size > 1
            raise AmbiguousLookupError,
                  "Ambiguous match for #{path.inspect}. Matches the following: #{candidates.inspect}"
          end

          candidates.first
        end
      end

      def _score(prefix, match)
        prefix_path = Util.array(match.scoped_prefix)
        matching_parts = prefix_path & prefix

        if matching_parts == prefix
          hits = matching_parts.size
          misses = hits - prefix_path.size

          [hits, misses]
        end
      end
    end
  end
end
