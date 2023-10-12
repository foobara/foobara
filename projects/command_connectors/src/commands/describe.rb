module Foobara
  module CommandConnectors
    module Commands
      class Describe < Foobara::Command
        inputs manifestable: :duck
        result :associative_array

        def execute
          build_manifest
        end

        def build_manifest
          manifestable.manifest
        end
      end
    end
  end
end
