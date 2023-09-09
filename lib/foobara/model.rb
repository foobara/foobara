module Foobara
  class Model
    class << self
      def subclass(strict_type_declaration)
        namespace = TypeDeclarations::Namespace.current

        model_name = strict_type_declaration[:name]

        # Can we use a symbol instead?
        handler = namespace.handler_for_class(TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration)
        attributes_type_declaration = strict_type_declaration[:attributes_declaration]
        attributes_type = handler.process_value!(attributes_type_declaration)

        # How are we going to set the domain and organization?
        Class.new(self) do
          singleton_class.define_method :name do
            model_name
          end

          singleton_class.define_method :model_name do
            model_name
          end

          singleton_class.define_method :attributes_type do
            attributes_type
          end

          attributes_type.element_types.each_key do |attribute_name|
            define_method attribute_name do
              attributes[attribute_name]
            end

            # TODO: let's cache validation_errors and clobber caches when updating this for performance reasons
            define_method "#{attribute_name}=" do |value|
              attribute_type = attributes_type.element_types[attribute_name]

              outcome = attribute_type.process_value(value)

              value = outcome.result if outcome.success?

              attributes[attribute_name] = value
            end
          end
        end
      end
    end

    # TODO: how are we going to set this??
    attr_accessor :domain

    def initialize(attributes = nil)
      attributes&.each_pair do |attribute_name, value|
        send("#{attribute_name}=", value)
      end
    end

    delegate :model_name, :attributes_type, to: :class
    delegate :organization, to: :domain, allow_nil: true

    def attributes
      @attributes ||= {}
    end

    def valid?
      attributes_type.process_value(attributes).success?
    end

    def validation_errors
      attributes_type.process_value(attributes).errors
    end
  end
end
