require "inheritable_thread_vars"

module Foobara
  class Model
    class NoSuchAttributeError < StandardError; end
    class AttributeIsImmutableError < StandardError; end

    include Concerns::Types
    include Concerns::Reflection
    include Concerns::Aliases
    include Concerns::Classes

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
          domain = model_type.foobara_domain

          if domain == GlobalDomain
            module_name = model_type.declaration_data[:model_module]

            begin
              Domain.to_domain(module_name)
            rescue Domain::NoSuchDomain
              module_to_check = module_name

              loop do
                domain = if Object.const_defined?(module_to_check)
                           return Domain.domain_through_modules(Object.const_get(module_to_check))
                         elsif module_to_check.include?("::")
                           module_to_check = module_to_check.split("::")[..-2].join("::")
                         else
                           return GlobalDomain
                         end
              end
            end
          else
            domain
          end
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
        if foobara_type&.scoped_path_set?
          foobara_type.scoped_name
        else
          Util.non_full_name(self) || model_name&.split("::")&.last
        end
      end

      def foobara_name
        foobara_model_name
      end

      def full_model_name
        [*model_type&.scoped_full_name, model_name].max_by(&:size)
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
          # Hmmm, can't there still be errors even if it's immutable?
          []
        end
      end

      # will create an anonymous subclass
      # TODO: change to a normal parameter since it's just name
      def subclass(name:)
        name = name.to_s if name.is_a?(::Symbol)

        # TODO: How are we going to set the domain and organization?
        Class.new(self) do
          singleton_class.define_method :model_name do
            name
          end
        end
      end
    end

    abstract

    attr_accessor :mutable, :skip_validations

    ALLOWED_OPTIONS = [:validate, :mutable, :ignore_unexpected_attributes, :skip_validations].freeze

    def initialize(attributes = nil, options = {})
      invalid_options = options.keys - ALLOWED_OPTIONS

      unless invalid_options.empty?
        # :nocov:
        raise ArgumentError, "Invalid options #{invalid_options} expected only #{ALLOWED_OPTIONS}"
        # :nocov:
      end

      self.skip_validations = options[:skip_validations]

      if options[:ignore_unexpected_attributes]
        Thread.with_inheritable_thread_local_var(:foobara_ignore_unexpected_attributes, true) do
          initialize(attributes, options.except(:ignore_unexpected_attributes))
          return
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
        if Thread.inheritable_thread_local_var_get(:foobara_ignore_unexpected_attributes)
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

      validate! if validate # TODO: test this code path
    end

    def model_name
      self.class.model_name
    end

    def valid_attribute_name?(attribute_name)
      # :nocov:
      self.class.valid_attribute_name?(attribute_name)
      # :nocov:
    end

    def validate_attribute_name!(attribute_name)
      self.class.validate_attribute_name!(attribute_name)
    end

    def attributes
      @attributes ||= {}
    end

    def attributes_with_delegates
      h = self.class.delegates.keys.to_h do |delegated_attribute_name|
        [delegated_attribute_name, send(delegated_attribute_name)]
      end

      attributes.merge(h)
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
      attributes_type.process_value(attributes).error_collection
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
