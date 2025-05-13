module Foobara
  class AttributesTransformers < TypeDeclarations::TypedTransformer
    class << self
      def symbol_for_attribute_names(attribute_names)
        attribute_names.sort.join("__")&.to_sym
      end
    end

    def initialize(...)
      super

      unless scoped_path_set?
        self.scoped_path = self.class.scoped_path
      end
    end
  end
end
