module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Commands
        class Help < Command
          description "Will extract items from the request to help with. Assumes the help is desired in HTML format"

          inputs request: Request

          result :string

          def execute
            load_manifest
            determine_relevant_manifest_to_help_with
            determine_template
            generate_html_from_template

            html
          end

          attr_accessor :raw_manifest, :root_manifest, :object_to_help_with, :template, :html

          def load_manifest
            self.raw_manifest = command_connector.foobara_manifest
            self.root_manifest = Manifest::RootManifest.new(raw_manifest)
          end

          def determine_relevant_manifest_to_help_with(mode: Namespace::LookupMode::GENERAL)
            arg = request.argument
            result = command_connector.foobara_lookup(arg)

            if result
              self.object_to_help_with = result
            else
              result = GlobalOrganization.foobara_lookup(arg)

              if result && root_manifest.contains?(result.foobara_manifest_reference,
                                                   result.scoped_category)
                self.object_to_help_with = result
              elsif mode == Namespace::LookupMode::GENERAL
                determine_relevant_manifest_to_help_with(mode: Namespace::LookupMode::RELAXED)
              else
                # TODO: add an input error instead...
                raise "cannot find #{arg}"
              end
            end
          end

          def manifest_to_help_with
            @manifest_to_help_with ||= begin
                                         adsf

                                         root_manifest.
                                       end
          end

          def command_connector
            request.command_connector
          end
        end
      end
    end
  end
end
