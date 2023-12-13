module Foobara
  # TODO: either make this an abstract base class of ValueModel and Entity or rename it to ValueModel
  # and have Entity inherit from it...
  # TODO: also, why is this at the root level instead of in a project??
  class Model
    class NoSuchAttributeError < StandardError; end

    include Concerns::Types

    class << self
      attr_accessor :domain, :is_abstract

      def organization_name
        domain.foobara_organization_name
      end

      def domain_name
        domain.foobara_domain_name
      end

      # TODO: would be nice to make this a universal concept via a concern
      def abstract
        @is_abstract = true
      end

      def abstract?
        @is_abstract
      end

      def update_namespace
        return if @namespace_updated

        @namespace_updated = true

        # TODO: Feels like we should use the autoset_namespace helpers here
        mod = Util.module_for(self)

        while mod
          if mod.foobara_domain?
            namespace = mod
            break
          end

          mod = Util.module_for(mod)
        end

        self.domain = if namespace&.foobara_domain?
                        namespace
                      else
                        GlobalDomain
                      end
      end

      def namespace
        domain.foobara_type_namespace
      end

      def attribute_names
        attributes_type.element_types.keys
      end

      def valid_attribute_name?(attribute_name)
        attribute_names.include?(attribute_name.to_sym)
      end

      def validate_attribute_name!(attribute_name)
        unless valid_attribute_name?(attribute_name)
          raise NoSuchAttributeError, "No such attribute #{attribute_name} expected one of #{attribute_names}"
        end
      end

      def model_name
        model_type&.scoped_name || Util.non_full_name(self)
      rescue Foobara::Scoped::NoScopedPathSetError
        Util.non_full_name(self)
      end

      def model_symbol
        model_name.to_sym
      end

      def full_model_name
        model_type&.scoped_full_name
      end

      def possible_errors
        attributes_type.possible_errors
      end

      def allowed_subclass_opts
        %i[name model_module]
      end

      def subclass(**opts)
        invalid_opts = opts.keys - allowed_subclass_opts

        unless invalid_opts.empty?
          # :nocov:
          raise ArgumentError, "Invalid opts #{invalid_opts} expected only #{allowed_subclass_opts}"
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

    def initialize(attributes = nil, options = {})
      allowed_options = [:validate]
      invalid_options = options.keys - allowed_options

      unless invalid_options.empty?
        # :nocov:
        raise ArgumentError, "Invalid options #{invalid_options} expected only #{allowed_options}"
        # :nocov:
      end

      validate = options[:validate]

      if attributes.nil?
        if validate
          # :nocov:
          raise ArgumentError, "Cannot use validate option without attributes"
          # :nocov:
        end
      else
        attributes.each_pair do |attribute_name, value|
          write_attribute(attribute_name, value)
        end
      end

      validate! if validate
    end

    foobara_delegate :model_name, :valid_attribute_name?, :validate_attribute_name!, to: :class

    def attributes
      @attributes ||= {}
    end

    def write_attribute(attribute_name, value)
      attribute_name = attribute_name.to_sym
      outcome = cast_attribute(attribute_name, value)
      attributes[attribute_name] = outcome.success? ? outcome.result : value
    end

    def write_attribute!(attribute_name, value)
      attribute_name = attribute_name.to_sym
      attributes[attribute_name] = cast_attribute!(attribute_name, value)
    end

    def write_attributes(attributes)
      attributes.each_pair do |attribute_name, value|
        write_attribute(attribute_name, value)
      end
    end

    def write_attributes!(attributes)
      attributes.each_pair do |attribute_name, value|
        write_attribute!(attribute_name, value)
      end
    end

    def read_attribute(attribute_name)
      attributes[attribute_name.to_sym]
    end

    def read_attribute!(attribute_name)
      validate_attribute_name!(attribute_name)
      read_attribute(attribute_name)
    end

    def cast_attribute(attribute_name, value)
      attribute_type = attributes_type.element_types[attribute_name]

      return Outcome.success(value) unless attribute_type

      attribute_type.process_value(value).tap do |outcome|
        unless outcome.success?
          outcome.errors.each do |error|
            error.prepend_path!(attribute_name)
          end
        end
      end
    end

    def cast_attribute!(attribute_name, value)
      validate_attribute_name!(attribute_name)

      outcome = cast_attribute(attribute_name, value)
      outcome.raise!
      outcome.result
    end

    def valid?
      attributes_type.process_value(attributes).success?
    end

    def validation_errors
      attributes_type.process_value(attributes).errors
    end

    def validate!
      attributes_type.process_value!(attributes)
    end

    def ==(other)
      self.class == other.class && attributes == other.attributes
    end

    def eql?(other)
      self == other
    end

    def hash
      attributes.hash
    end
  end
end
