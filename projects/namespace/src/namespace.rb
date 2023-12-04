module Foobara
  class Namespace
    include IsNamespace

    class NotFoundError < StandardError; end

    def initialize(scoped_name_or_path = nil, parent_namespace: nil)
      NamespaceHelpers.initialize_foobara_namespace(self, scoped_name_or_path, parent_namespace:)
    end
  end
end
