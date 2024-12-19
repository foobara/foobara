module Foobara
  module Monorepo
    # TODO: make this MonorepoProject and have a more generic Project so that other projects outside of the
    # repo can have things like reset_all called on th.
    class Project
      attr_accessor :symbol, :project_path

      # TODO: we should move these concepts out of "Monorepo" and maybe into Foobara because we sometimes need to
      # be able to install!/reset foobara code that's been extracted into a gem
      def initialize(symbol, project_path: nil)
        self.symbol = symbol
        self.project_path = project_path || "#{__dir__}/../../../../../projects/#{symbol}"
      end

      def require_path
        "foobara/#{symbol}"
      end

      def module_name
        Util.classify(symbol)
      end

      def module
        Foobara.const_get(module_name)
      end

      def load
        require require_path
        Util.require_directory("#{project_path}/src")
      end

      def install!
        if self.module.respond_to?(:install!)
          self.module.install!
        end
      end

      def reset_all
        if self.module.respond_to?(:reset_all)
          self.module.reset_all
        end
      end

      def new_project_added(project)
        if self.module.respond_to?(:new_project_added)
          self.module.new_project_added(project)
        end
      end
    end
  end
end
