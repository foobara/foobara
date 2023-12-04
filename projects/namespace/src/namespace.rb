module Foobara
  class Namespace
    include IsNamespace

    class NotFoundError < StandardError; end

    def initialize(scoped_name_or_path, accesses: [], parent_namespace: nil)
      initialize_foobara_namespace(scoped_name_or_path, accesses:, parent_namespace:)
    end
  end
end
