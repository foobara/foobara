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

  module Monorepo
    class << self
      def all_projects
        @all_projects ||= []
      end

      def projects(*symbols)
        symbols.each do |symbol|
          all_projects << Project.new(symbol).tap(&:load)
        end
      end

      def project(symbol)
        projects(symbol)
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
