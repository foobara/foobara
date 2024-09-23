module Foobara
  class CommandConnector
    module Commands
      class Describe < Foobara::Command
        inputs manifestable: :duck,
               request: :duck
        result :associative_array

        def execute
          build_manifest
          stamp_request_metadata

          manifest
        end

        attr_accessor :manifest

        def build_manifest
          self.manifest = if manifestable.is_a?(CommandConnector)
                            manifestable.foobara_manifest
                          else
                            manifestable.foobara_manifest(to_include: Set.new)
                          end
        end

        def stamp_request_metadata
          manifest[:metadata] = { when: Time.now }
        end
      end
    end
  end
end
