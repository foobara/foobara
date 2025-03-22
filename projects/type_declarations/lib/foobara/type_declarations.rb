module Foobara
  module TypeDeclarations
    class << self
      def reset_all
        # TODO: this doesn't really belong here. I think we need to maybe call reset in reverse order?
        Foobara::Domain::DomainModuleExtension.all.each do |domain|
          var = "@foobara_type_builder"

          if domain.instance_variable_defined?(var)
            domain.remove_instance_variable(var)
          end
        end

        Util.descendants(Error).each do |error_class|
          if error_class.instance_variable_defined?(:@context_type)
            error_class.remove_instance_variable(:@context_type)
          end
        end

        %w[
          foobara_children
          foobara_registry
          foobara_type_builder
        ].each do |var_name|
          var_name = "@#{var_name}"

          # Don't we only have to do this for Foobara and not all of these??
          [
            Namespace.global,
            Foobara::GlobalOrganization,
            Foobara::GlobalDomain,
            Domain,
            Command,
            Types::Type,
            Value::Processor,
            Error
          ].each do |klass|
            klass.remove_instance_variable(var_name) if klass.instance_variable_defined?(var_name)
          end
        end

        if GlobalDomain.const_defined?(:Types, false)
          GlobalDomain::Types.instance_variable_set(
            :@foobara_lowercase_constants,
            @original_foobara_lowercase_constants || []
          )
          GlobalDomain.send(:remove_const, :Types)
        end

        @original_scoped.each do |scoped|
          Namespace.global.foobara_register(scoped)
        end

        @original_children.each do |child|
          Namespace.global.foobara_children << child
        end

        GlobalDomain.foobara_parent_namespace = GlobalOrganization
        GlobalOrganization.foobara_register(GlobalDomain)

        register_type_declaration(Handlers::RegisteredTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendRegisteredTypeDeclaration.new)
        array_handler = Handlers::ExtendArrayTypeDeclaration.new
        register_type_declaration(array_handler)
        register_type_declaration(Handlers::ExtendAssociativeArrayTypeDeclaration.new)
        attributes_handler = Handlers::ExtendAttributesTypeDeclaration.new
        register_type_declaration(attributes_handler)
        register_type_declaration(Handlers::ExtendTupleTypeDeclaration.new)

        @sensitive_type_removers = nil

        register_sensitive_type_remover(SensitiveTypeRemovers::Attributes.new(attributes_handler))
        register_sensitive_value_remover(attributes_handler, SensitiveValueRemovers::Attributes)
        register_sensitive_type_remover(SensitiveTypeRemovers::Array.new(array_handler))
        register_sensitive_value_remover(array_handler, SensitiveValueRemovers::Array)
      end

      def install!
        capture_current_namespaces

        reset_all

        Foobara::Error.include(ErrorExtension)

        Value::Processor::Casting::CannotCastError.singleton_class.define_method :context_type_declaration do
          {
            cast_to: :duck,
            value: :duck,
            attribute_name: :symbol
          }
        end

        Value::Processor::Selection::NoApplicableProcessorError.singleton_class.define_method(
          :context_type_declaration
        ) do
          {
            processor_names: [:symbol],
            value: :duck
          }
        end

        Value::Processor::Selection::MoreThanOneApplicableProcessorError.singleton_class.define_method(
          :context_type_declaration
        ) do
          {
            applicable_processor_names: [:symbol],
            processor_names: [:symbol],
            value: :duck
          }
        end

        Value::DataError.singleton_class.define_method :context_type_declaration do
          {
            attribute_name: :symbol,
            value: :duck
          }
        end
      end

      def new_project_added(_project)
        capture_current_namespaces
      end

      def capture_current_namespaces
        # TODO: this feels like the wrong place to do this but doing it here for now to make sure it's done when
        # most important
        @original_scoped = Namespace.global.foobara_registry.all_scoped.dup
        @original_children = Namespace.global.foobara_children.dup

        if GlobalDomain.const_defined?(:Types, false)
          # :nocov:
          @original_foobara_lowercase_constants =
            GlobalDomain::Types.instance_variable_get(:@foobara_lowercase_constants).dup
          # :nocov:
        end
      end
    end
  end
end
