module Foobara
  module CommandConnectors
    module Commands
      class Describe < Foobara::Command
        inputs manifestable: :duck
        result :associative_array

        def execute
          binding.pry
          build_manifest
        end

        def to_include
          @to_include ||= if manifestable.is_a?(CommandConnector)
                            nil
                          else
                            Set.new
                          end
        end

        def build_manifest
          manifestable.foobara_manifest(to_include:)
        end
      end
    end
  end
end
