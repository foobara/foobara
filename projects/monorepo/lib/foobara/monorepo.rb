require_relative "monorepo/project"

module Foobara
  class << self
    def require_project_file(project, path)
      require_relative("../../../#{project}/src/#{path}")
    end

    def reset_alls
      Monorepo.reset_alls
    end
  end

  # TODO: We should rename this to Projects or something else because we need to manage this stuff for projects
  # inside and outside of the monorepo.
  module Monorepo
    class << self
      attr_accessor :is_installed

      def all_projects
        @all_projects ||= {}
      end

      def projects(*symbols)
        symbols.each do |symbol|
          project(symbol)
        end
      end

      def project(symbol, project_path: nil)
        if all_projects.key?(symbol)
          # :nocov:
          raise ArgumentError, "Project #{symbol} already loaded"
          # :nocov:
        end

        project = Project.new(symbol, project_path:)
        project.load

        all_projects[symbol] = project

        if is_installed
          project.install!

          all_projects.each_pair do |key, existing_project|
            next if key == symbol

            existing_project.new_project_added(project)
          end
        end
      end

      def install!
        self.is_installed = true
        all_projects.each_value(&:install!)
      end

      def reset_alls
        all_projects.each_value(&:reset_all)
      end
    end
  end
end
