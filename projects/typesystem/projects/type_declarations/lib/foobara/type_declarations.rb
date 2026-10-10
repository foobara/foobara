require "foobara/types"

module Foobara
  module TypeDeclarations
    class << self
      def reset_all(skip_check: nil)
        unless skip_check
          Foobara.raise_if_production!
        end

        Util.descendants(Error).each do |error_class|
          if error_class.instance_variable_defined?(:@context_type)
            error_class.remove_instance_variable(:@context_type)
          end
        end

        [
          :@foobara_children,
          :@foobara_registry,
          :@foobara_type_builder,
          :@lru_cache
        ].each do |var_name|
          namespaces_to_reset.each do |klass|
            if klass.instance_variable_defined?(var_name)
              klass.remove_instance_variable(var_name)
            end
          end
        end

        Namespace.clear_lru_cache!

        @original_scoped.each_key do |namespace|
          scoped = @original_scoped[namespace]
          to_remove = []

          scoped.each do |child|
            if child.scoped_unregistered?
              to_remove << child
              next
            end

            unless namespace.foobara_registered?(child, mode: Namespace::LookupMode::DIRECT)
              namespace.foobara_register(child)
            end
          end

          children = namespace.foobara_children

          to_remove.each do |child|
            children.delete(child)
            scoped.delete(child)
          end

          to_remove.clear

          @original_children[namespace].each do |child|
            if child.scoped_unregistered?
              to_remove << child
              next
            end
            children << child unless children.include?(child)
          end

          to_remove.each do |child|
            @original_children[namespace].delete(child)
          end
        end

        Namespace.clear_lru_cache!

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

        Foobara::AttributesTransformers::Reject.foobara_unregister_all
        Foobara::AttributesTransformers::Only.foobara_unregister_all
      end

      def install!
        capture_current_namespaces

        reset_all(skip_check: true)

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

        ::Foobara::Value::DataError.instance_exec do
          class << self
            def context_type_declaration
              {
                attribute_name: :symbol,
                value: :duck
              }.freeze
            end
          end
        end
      end

      def new_project_added(_project)
        capture_current_namespaces
      end

      def start! = capture_current_namespaces

      private

      def capture_current_namespaces
        # TODO: this feels like the wrong place to do this but doing it here for now to make sure it's done when
        # most important
        @original_scoped = {}
        @original_children = {}

        namespaces_to_reset.each do |namespace|
          next unless namespace.is_a?(Namespace::IsNamespace)

          @original_scoped[namespace] = namespace.foobara_registry.all_scoped.dup
          @original_children[namespace] = namespace.foobara_children.dup
        end
      end

      def namespaces_to_reset
        [
          Foobara::GlobalDomain,
          Foobara::GlobalOrganization,
          Value::Processor,
          Types::Type,
          Domain,
          Error,
          Foobara,
          Namespace.global
        ]
      end
    end
  end
end

Foobara.project("type_declarations", project_path: "#{__dir__}/../..")
