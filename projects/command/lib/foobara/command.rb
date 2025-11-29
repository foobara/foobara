module Foobara
  class Command
    class << self
      def install!
        Namespace.global.foobara_add_category_for_subclass_of(:command, self)

        Domain::DomainModuleExtension::ClassMethods.prepend(
          DomainModuleExtensionExtension::ClassMethods
        )
      end
    end
  end
end

Foobara.project("command", project_path: "#{__dir__}/../..")
