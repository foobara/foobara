module Foobara
  class AttributesTransformers < TypeDeclarations::TypedTransformer
    def initialize(...)
      super

      unless scoped_path_set?
        self.scoped_path = self.class.scoped_path
      end
    end
  end
end
