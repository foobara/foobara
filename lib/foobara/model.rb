module Foobara
  class Model
    class << self
      attr_accessor :domain
      attr_reader :model_type

      delegate :organization, to: :domain, allow_nil: true

      def reset_all
        Foobara::Util.constant_values(self, extends: Foobara::Model).each do |dynamic_model|
          remove_const(dynamic_model.name.demodulize)
        end
      end

      def update_namespace
        return if @namespace_updated

        @namespace_updated = true

        mod = Util.module_for(self)

        self.domain = if mod&.foobara_domain?
                        mod.foobara_domain
                      else
                        Domain.global
                      end
      end

      def inherited(subclass)
        super
        subclass.update_namespace unless subclass.name.blank?
      end

      def attributes_type
        model_type.element_types
      end

      def namespace
        domain.type_namespace
      end

      def model_type=(model_type)
        if @model_type
          # :nocov:
          raise "Already set model type"
          # :nocov:
        end

        @model_type = model_type

        update_namespace

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

      def model_name
        # TODO: should get this from the declaration_data instead, right??
        name.demodulize
      end

      def attributes(attributes_type_declaration)
        update_namespace

        namespace.type_for_declaration(
          type: :model,
          name: model_name,
          model_class: self,
          model_base_class: superclass,
          attributes_declaration: attributes_type_declaration
        )

        unless @model_type
          # :nocov:
          raise "Expected model type to automatically be registered"
          # :nocov:
        end

        attributes_type
      end

      def possible_errors
        attributes_type.possible_errors
      end

      def subclass(**opts)
        allowed_opts = %i[name model_module]

        invalid_opts = opts.keys - allowed_opts

        if invalid_opts.present?
          # :nocov:
          raise ArgumentError, "Invalid opts #{invalid_opts} expected only #{allowed_opts}"
          # :nocov:
        end

        model_name = opts[:name]

        # TODO: How are we going to set the domain and organization?
        model_class = Class.new(self) do
          singleton_class.define_method :model_name do
            model_name
          end
        end

        if opts.key?(:model_module)
          model_module = opts[:model_module]
          model_module.const_set(model_name, model_class)
        end

        model_class
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
