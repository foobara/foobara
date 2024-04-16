module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Commands
        class Help < Command
          description "Will extract items from the request to help with. Assumes the help is desired in HTML format"
          inputs request: Request
          result :string
          possible_error CommandConnector::NotFoundError

          def execute
            load_manifest
            determine_object_to_help_with
            build_presenter
            load_template
            generate_html_from_template

            html
          end

          attr_accessor :raw_manifest, :root_manifest, :object_to_help_with, :template, :html, :presenter

          def load_manifest
            self.raw_manifest = command_connector.foobara_manifest
            self.root_manifest = Manifest::RootManifest.new(raw_manifest)
          end

          def determine_object_to_help_with(mode: Namespace::LookupMode::ABSOLUTE)
            arg = request.argument

            if arg
              result = command_connector.command_registry.foobara_lookup(arg, mode:)

              if result
                self.object_to_help_with = result
              else
                result = GlobalOrganization.foobara_lookup(arg, mode:)

                if result && root_manifest.contains?(result.foobara_manifest_reference,
                                                     result.scoped_category)
                  self.object_to_help_with = result
                elsif mode == Namespace::LookupMode::ABSOLUTE
                  determine_object_to_help_with(mode: Namespace::LookupMode::GENERAL)
                elsif mode == Namespace::LookupMode::GENERAL
                  determine_object_to_help_with(mode: Namespace::LookupMode::RELAXED)
                else
                  # TODO: add an input error instead for missing record to trigger 404
                  add_runtime_error(CommandConnector::NotFoundError.new(arg))
                end
              end
            else
              self.object_to_help_with = root_manifest
            end
          end

          def build_presenter
            self.presenter = Help::Presenter.for(manifest_to_help_with)
          end

          def template_path
            presenter.template_path
          end

          def load_template
            template_body = File.read(template_path)

            erb = ERB.new(template_body)
            erb.filename = template_path

            self.template = erb
          end

          def generate_html_from_template
            self.html = template.result(presenter.instance_eval { binding })
          end

          def manifest_to_help_with
            @manifest_to_help_with ||= if object_to_help_with.is_a?(Manifest::BaseManifest)
                                         object_to_help_with
                                       else
                                         root_manifest.lookup(object_to_help_with.foobara_manifest_reference)
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
