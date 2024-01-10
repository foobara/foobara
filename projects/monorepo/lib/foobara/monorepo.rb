require_relative "monorepo/project"

module Foobara
  class << self
    def require_file(project, path)
      Util.require_project_file(project, path)
    end

    def reset_alls
      Monorepo.reset_alls
    end
  end

  # TODO: We should rename this to Projects or something else because we need to manage this stuff for projects
  # inside and outside of the monorepo.
  module Monorepo
    class << self
      def all_projects
        @all_projects ||= []
      end

      def projects(*symbols)
        symbols.each do |symbol|
          project(symbol)
        end
      end

      def project(symbol)
        all_projects << Project.new(symbol).tap(&:load)
      end

      def install!
        all_projects.each(&:install!)
      end

      def reset_alls
        all_projects.each(&:reset_all)
      end
    end
  end
end
