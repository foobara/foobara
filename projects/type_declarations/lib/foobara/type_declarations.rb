module Foobara
  module TypeDeclarations
    class << self
      def reset_all
        Foobara::TypeDeclarations::Namespace.reset_all

        # TODO: this feels like the wrong place to do this but doing it here for now to make sure it's done when
        # most important
        @original_scoped ||= Foobara.foobara_registry.all_scoped
        @original_children ||= Foobara.foobara_children

        %w[
          foobara_children
          foobara_registry
          foobara_type_namespace
        ].each do |var_name|
          var_name = "@#{var_name}"

          # Don't we only have to do this for Foobara and not all of these??
          [
            Foobara,
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

        @original_scoped.each do |scoped|
          Foobara.foobara_register(scoped)
        end

        @original_children.each do |child|
          Foobara.foobara_children << child
        end

        GlobalDomain.foobara_parent_namespace = GlobalOrganization
        GlobalOrganization.foobara_register(GlobalDomain)

        register_type_declaration(Handlers::RegisteredTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendRegisteredTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendArrayTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendAssociativeArrayTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendAttributesTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendTupleTypeDeclaration.new)
      end

      def install!
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

        # TODO: this doesn't feel like the right place for this...
        Foobara::Error.singleton_class.define_method(
          :subclass
        ) do |superclass = self, symbol:, context_type_declaration:, message: nil|
          Util.make_class "#{superclass.name}::#{Util.classify(symbol)}", superclass do
            singleton_class.define_method :symbol do
              symbol
            end

            singleton_class.define_method :context_type_declaration do
              context_type_declaration
            end

            if message
              singleton_class.define_method :message do
                message
              end
            end
          end
        end
      end
    end
  end
end
