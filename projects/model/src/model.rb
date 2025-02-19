module Foobara
  # TODO: either make this an abstract base class of ValueModel and Entity or rename it to ValueModel
  # and have Entity inherit from it...
  # TODO: also, why is this at the root level instead of in a project??
  class Model
    class NoSuchAttributeError < StandardError; end
    class AttributeIsImmutableError < StandardError; end

    include Concerns::Types
    include Concerns::Reflection
    include Concerns::Aliases

    class << self
      attr_accessor :is_abstract

      def description(*args)
        case args.size
        when 0
          @description
        when 1
          @description = args.first
        else
          # :nocov:
          raise ArgumentError, "expected 0 or 1 argument, got #{args.size}"
          # :nocov:
        end
      end

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

      def closest_namespace_module
        # TODO: Feels like we should use the autoset_namespace helpers here
        mod = Util.module_for(self)

        while mod
          if mod.is_a?(Namespace::IsNamespace)
            namespace = mod
            break
          end

          mod = Util.module_for(mod)
        end

        if mod.nil? || mod == GlobalOrganization || mod == Foobara
          GlobalDomain
        else
          namespace
        end
      end

      def domain
        if model_type
          model_type.foobara_domain
        else
          Domain.domain_through_modules(self)
        end
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

      def foobara_model_name
        foobara_type&.scoped_name || Util.non_full_name(self)
      rescue Foobara::Scoped::NoScopedPathSetError
        # :nocov:
        Util.non_full_name(self)
        # :nocov:
      end

      def full_model_name
        model_type&.scoped_full_name
      end

      def possible_errors(mutable: true)
        if mutable == true
          attributes_type.possible_errors
        elsif mutable
          element_types = attributes_type.element_types

          p = []

          Util.array(mutable).each do |attribute_name|
            attribute_name = attribute_name.to_sym

            # TODO: this doesn't feel quite right... we should be excluding errors so that we don't
            # miss any that are on attributes_type unrelated to the elements.
            element_types[attribute_name].possible_errors.each do |possible_error|
              possible_error = possible_error.dup
              possible_error.prepend_path!(attribute_name)
              p << possible_error
            end
          end

          p
        else
          []
        end
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

        if model_name.is_a?(::Symbol)
          model_name = model_name.to_s
        end

        # TODO: How are we going to set the domain and organization?
        model_class = Class.new(self) do
          singleton_class.define_method :model_name do
            model_name
          end
        end

        if opts.key?(:model_module)
          model_module = opts[:model_module]

          if model_name.include?("::")
            model_module_name = "#{model_module.name}::#{model_name.split("::")[..-2].join("::")}"
            model_module = Util.make_module_p(model_module_name, tag: true)
          end

          const_name = model_name.split("::").last

          model_module.const_set(const_name, model_class)
        end

        model_class
      end
    end

    abstract

    attr_accessor :mutable

    def initialize(attributes = nil, options = {})
      allowed_options = %i[validate mutable ignore_unexpected_attributes]
      invalid_options = options.keys - allowed_options

      unless invalid_options.empty?
        # :nocov:
        raise ArgumentError, "Invalid options #{invalid_options} expected only #{allowed_options}"
        # :nocov:
      end

      if options[:ignore_unexpected_attributes]
        Thread.foobara_with_var(:foobara_ignore_unexpected_attributes, true) do
          return initialize(attributes, options.except(:ignore_unexpected_attributes))
        end
      end

      validate = options[:validate]

      if attributes.nil?
        if validate
          # :nocov:
          raise ArgumentError, "Cannot use validate option without attributes"
          # :nocov:
        end
      else
        if Thread.foobara_var_get(:foobara_ignore_unexpected_attributes)
          outcome = attributes_type.process_value(attributes)

          if outcome.success?
            attributes = outcome.result
          end
        end

        self.mutable = true
        attributes.each_pair do |attribute_name, value|
          write_attribute(attribute_name, value)
        end
      end

      mutable = if options.key?(:mutable)
                  options[:mutable]
                elsif self.class.model_type.declaration_data.key?(:mutable)
                  self.class.model_type.declaration_data[:mutable]
                else
                  # why do we default to true here but false in the transformers?
                  true
                end

      self.mutable = if mutable.is_a?(::Array)
                       mutable.map(&:to_sym)
                     else
                       mutable
                     end

      validate! if validate
    end

    foobara_delegate :model_name, :valid_attribute_name?, :validate_attribute_name!, to: :class

    def attributes
      @attributes ||= {}
    end

    def write_attribute(attribute_name, value)
      attribute_name = attribute_name.to_sym

      if mutable == true || (mutable != false && mutable&.include?(attribute_name))
        outcome = cast_attribute(attribute_name, value)
        attributes[attribute_name] = outcome.success? ? outcome.result : value
      else
        # :nocov:
        raise AttributeIsImmutableError, "Cannot write attribute #{attribute_name} because it is not mutable"
        # :nocov:
      end
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
      attributes[attribute_name&.to_sym]
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

    def to_h
      attributes
    end

    def to_json(*_args)
      to_h.to_json
    end
  end
end
