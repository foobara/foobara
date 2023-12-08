module Foobara
  module TypeDeclarations
    class << self
      def reset_all
        Foobara::TypeDeclarations::Namespace.reset_all

        # TODO: this feels like the wrong place to do this but doing it here for now to make sure it's done when
        # most important
        @original_scoped ||= Foobara.foobara_registry.each_scoped.to_a
        binding.pry
        Foobara.instance_variable_set("@foobara_registry", nil)
        Foobara.instance_variable_set("@foobara_children", nil)

        @original_scoped.each do |scoped|
          Foobara.foobara_register(scoped)
        end

        register_type_declaration(Handlers::RegisteredTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendRegisteredTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendArrayTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendAssociativeArrayTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendAttributesTypeDeclaration.new)
        register_type_declaration(Handlers::ExtendTupleTypeDeclaration.new)
      end

      def install!
        binding.pry
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
