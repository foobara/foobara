module Foobara
  # TODO: Make some kind of module to house these methods instead of the Command class
  class Service; end

  class Command
    class << self
      def install!
        Namespace.global.foobara_add_category_for_subclass_of(:command, self)
      end
    end
  end
end

Foobara.project("command", project_path: "#{__dir__}/../..")
