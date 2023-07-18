module Foobara
  class Domain
    module CommandExtension
      extend ActiveSupport::Concern

      class_methods do
        def domain
          namespace = Foobara::Util.module_for(self)

          if namespace&.ancestors&.include?(Foobara::Domain)
            namespace.instance
          end
        end
      end
    end
  end
end
