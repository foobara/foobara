module Foobara
  class Namespace
    include IsNamespace

    class NotFoundError < StandardError; end

    def initialize(scoped_name_or_path, accesses: [], parent_namespace: nil)
      if parent_namespace
        self.namespace = parent_namespace
        parent_namespace.children << self
      end

      self.accesses = Util.array(accesses)

      self.scoped_path = if scoped_name_or_path.is_a?(String)
                           scoped_name_or_path.split("::")
                         else
                           scoped_name_or_path
                         end
    end
  end
end
