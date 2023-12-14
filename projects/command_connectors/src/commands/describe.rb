module Foobara
  module CommandConnectors
    module Commands
      class Describe < Foobara::Command
        inputs manifestable: :duck
        result :associative_array

        def execute
          build_manifest
        end

        attr_accessor :manifest

        def build_manifest
          self.manifest = if manifestable.is_a?(CommandConnector)
                            manifestable.foobara_manifest
                          else
                            manifestable.foobara_manifest(to_include: Set.new)
                          end
        end
      end
    end
  end
end
