module Foobara
  class Model
    class << self
      attr_accessor :attributes_type, :namespace, :domain

      delegate :organization, to: :domain, allow_nil: true

      def reset_all
        Foobara::Util.constant_values(self, extends: Foobara::Model).each do |dynamic_model|
          remove_const(dynamic_model.name.demodulize)
        end
      end

      def update_namespace
        mod = Util.module_for(self)

        if mod&.foobara_domain?
          self.domain = mod.foobara_domain
          self.namespace = domain.type_namespace
        else
          self.namespace = TypeDeclarations::Namespace::GLOBAL
        end
      end

      def model_type
        return @model_type if defined?(@model_type)

        @model_type = namespace.type_for_declaration(model_type_declaration)
      end

      def model_type_declaration
        {
          type: :model,
          name: model_name,
          model_class: self,
          model_base_class: superclass,
          attributes_declaration: attributes_type.declaration_data
        }
      end

      def model_name
        name.demodulize
      end

      def attributes(attributes_type_declaration)
        update_namespace
        self.attributes_type = attributes_declaration_to_type(attributes_type_declaration)
        register_model_type
      end

      def register_model_type
        domain&.register_model(self)
      end

      def possible_errors
        attributes_type.possible_errors
      end

      def attributes_declaration_to_type(attributes_type_declaration)
        handler = namespace.handler_for_class(TypeDeclarations::Handlers::ExtendAttributesTypeDeclaration)
        handler.process_value!(attributes_type_declaration)
      end

      def subclass(strict_type_declaration)
        model_name = strict_type_declaration[:name]

        # TODO: How are we going to set the domain and organization?
        Class.new(self) do
          self.namespace = TypeDeclarations::Namespace.current

          attributes(strict_type_declaration[:attributes_declaration])

          singleton_class.define_method :name do
            model_name
          end

          singleton_class.define_method :model_name do
            model_name
          end

          attributes_type.element_types.each_key do |attribute_name|
            define_method attribute_name do
              attributes[attribute_name]
            end

            # TODO: let's cache validation_errors and clobber caches when updating this for performance reasons
            define_method "#{attribute_name}=" do |value|
              write_attribute(attribute_name, value)
            end
          end
        end
      end
    end

    def initialize(attributes = nil)
      attributes&.each_pair do |attribute_name, value|
        write_attribute(attribute_name, value)
      end
    end

    delegate :model_name, :attributes_type, to: :class

    def attributes
      @attributes ||= {}
    end

    def write_attribute(attribute_name, value)
      attribute_type = attributes_type.element_types[attribute_name]

      if attribute_type
        outcome = attribute_type.process_value(value)

        value = outcome.result if outcome.success?
      end

      attributes[attribute_name] = value
    end

    def valid?
      attributes_type.process_value(attributes).success?
    end

    def validation_errors
      attributes_type.process_value(attributes).errors
    end

    def ==(other)
      return false unless self.class == other.class

      attributes == other.attributes
    end

    def eql?(other)
      self == other
    end

    def hash
      attributes.hash
    end
  end
end
