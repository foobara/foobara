require_relative "presenter/command"
require_relative "presenter/entity"
require_relative "presenter/error"
require_relative "presenter/model"
require_relative "presenter/organization"
require_relative "presenter/domain"
require_relative "presenter/processor"
require_relative "presenter/processor_class"
require_relative "presenter/root"
require_relative "presenter/type"

module Foobara
  module CommandConnectors
    class Http < CommandConnector
      module Commands
        class Help < Command
          class Presenter
            class << self
              def for(manifest)
                case manifest
                when Manifest::RootManifest
                  Presenter::Root
                when Manifest::Command
                  Presenter::Command
                when Manifest::Entity
                  Presenter::Entity
                when Manifest::Model
                  Presenter::Model
                when Manifest::Type
                  Presenter::Type
                when Manifest::Error
                  Presenter::Error
                when Manifest::Domain
                  Presenter::Domain
                when Manifest::Organization
                  Presenter::Organization
                when Manifest::Processor
                  Presenter::Processor
                when Manifest::ProcessorClass
                  Presenter::ProcessorClass
                else
                  raise "No presenter found for #{manifest.path}"
                end.new(manifest)
              end

              def template_symbol
                Util.underscore(Util.non_full_name(self))
              end

              def template_path
                template_path = File.join(
                  __dir__,
                  "templates",
                  "#{template_symbol}.html.erb"
                )
                Pathname.new(template_path).cleanpath.to_s
              end
            end

            attr_accessor :manifest

            def initialize(manifest)
              self.manifest = manifest
            end

            def template_path
              self.class.template_path
            end

            def method_missing(method_name, *, &)
              if manifest.respond_to?(method_name)
                manifest.send(method_name, *, &)
              else
                # :nocov:
                super
                # :nocov:
              end
            end

            def respond_to_missing?(method_name, include_private = false)
              manifest.respond_to?(method_name, include_private)
            end
          end
        end
      end
    end
  end
end
