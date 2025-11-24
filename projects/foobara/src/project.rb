module Foobara
  class Project
    attr_accessor :symbol, :project_path

    def initialize(symbol, project_path: nil)
      self.symbol = symbol
      self.project_path = project_path || "#{__dir__}/../../#{symbol}"
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

      src_dir = "#{project_path}/src"

      if Dir.exist?(src_dir)
        Util.require_directory(src_dir)
      end
    end

    def install!
      if self.module.respond_to?(:install!)
        self.module.install!
      end
    end

    def reset_all
      Foobara.raise_if_production!("reset_all")

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
