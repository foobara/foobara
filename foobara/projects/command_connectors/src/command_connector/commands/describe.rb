require_relative "../../../../../../version"

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
          self.manifest = manifestable.foobara_manifest
        end

        def stamp_request_metadata
          manifest[:metadata] = { when: Time.now, foobara_version: Foobara::Version::VERSION }
        end
      end
    end
  end
end
