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
                  # :nocov:
                  raise "No presenter found for #{manifest.path}"
                  # :nocov:
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

            def render_html_list(data, skip_wrapper: false)
              html = ""

              case data
              when ::Hash
                html << "<ul>" unless skip_wrapper
                data.each do |key, value|
                  html << "<li>#{key}"
                  html << "<ul>"
                  html << render_html_list(value, skip_wrapper: true)
                  html << "</ul>"
                  html << "</li>"
                end
                html << "</ul>" unless skip_wrapper
              when ::Array
                html << "<ul>" unless skip_wrapper
                data.each do |item|
                  html << render_html_list(item)
                end
                html << "</ul>" unless skip_wrapper
              when Manifest::Attributes
                html << "<ul>" unless skip_wrapper
                data.relevant_manifest.each_pair do |key, value|
                  if key.to_s == "type"
                    next
                  end

                  if key.to_s == "element_type_declarations"
                    key = :attributes
                    value = data.attribute_declarations
                  end
                  html << "<li>#{key}"
                  html << "<ul>"
                  html << render_html_list(value, skip_wrapper: true)
                  html << "</ul>"
                  html << "</li>"
                end
                html << "</ul>" unless skip_wrapper
              when Manifest::Array
                html << "<ul>" unless skip_wrapper
                data.relevant_manifest.each_pair do |key, value|
                  next if key == :element_type_declaration

                  if key.to_s == "type"
                    value = root_manifest.lookup_path(key, value)
                  end
                  html << "<li>#{key}"
                  html << "<ul>"
                  html << render_html_list(value, skip_wrapper: true)
                  html << "</ul>"
                  html << "</li>"
                end
                html << render_html_list({ element_type: data.element_type }, skip_wrapper: true)
                html << "</ul>" unless skip_wrapper
              when Manifest::TypeDeclaration
                html << "<ul>" unless skip_wrapper
                data.relevant_manifest.each_pair do |key, value|
                  if key.to_s == "type"
                    value = root_manifest.lookup_path(key, value)
                  end
                  html << "<li>#{key}"
                  html << "<ul>"
                  html << render_html_list(value, skip_wrapper: true)
                  html << "</ul>"
                  html << "</li>"
                end
                html << "</ul>" unless skip_wrapper
              when Manifest::Type, Manifest::Command, Manifest::Error
                html << foobara_reference_link(data)
              when Manifest::PossibleError
                html << render_html_list(data.error)
              else
                html << "<li>#{data}</li>"
              end

              html
            end

            def foobara_reference_link(manifest)
              path = "/help/#{manifest.reference}"

              "<a href=\"#{path}\">#{manifest.reference.split("::").last}</a>"
            end

            def root_manifest
              @root_manifest ||= Manifest::RootManifest.new(manifest.root_manifest)
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
