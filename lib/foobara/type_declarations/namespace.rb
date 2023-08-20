module Foobara
  module TypeDeclarations
    class Namespace
      class << self
        def new(...)
          super.tap do |instance|
            namespaces << instance
          end
        end

        def namespaces
          @namespaces ||= []
        end

        def namespace_for_symbol(symbol)
          namespace = namespaces.find { |n| n.name == symbol }

          unless namespace
            raise "Could not find namespace for #{symbol}"
          end

          namespace
        end

        def current
          Thread.current[:foobara_namespace]
        end

        def using(namespace_or_symbol)
          namespace = if namespace_or_symbol.is_a?(Namespace)
                        namespace_or_symbol
                      elsif namespace_or_symbol.is_a?(Symbol)
                        namespace_for_symbol(namespace_or_symbol)
                      else
                        raise ArgumentError, "Expected #{namespace_or_symbol} to be a symbol or namespace"
                      end

          old_namespace = current

          begin
            Thread.current[:foobara_namespace] = namespace
            yield
          ensure
            Thread.current[:foobara_namespace] = old_namespace
          end
        end

        delegate :type_registered,
                 :type_registries,
                 :type_for_symbol,
                 :type_declaration_handler_registries,
                 :type_declaration_handler_for,
                 :type_declaration_handler_for_handler_class,
                 :handlers,
                 :type_for_declaration,
                 to: :current
      end

      attr_accessor :name, :type_declaration_handler_registry, :type_registry, :accesses

      def initialize(
        name,
        type_declaration_handler_registry: TypeDeclarations::TypeDeclarationHandlerRegistry.new(enforce_unique: false),
        type_registry: Types::Registry.new,
        accesses: [GLOBAL]
      )
        self.name = name
        self.type_declaration_handler_registry = type_declaration_handler_registry
        self.type_registry = type_registry

        self.accesses = accesses
      end

      GLOBAL = new(
        :global,
        type_registry: Types.global_registry,
        accesses: []
      )

      Thread.current[:foobara_namespace] = GLOBAL

      # types

      def register_type(symbol, type)
        type_registry[symbol] = type
      end

      def type_registered?(symbol)
        type_registries.any? { |registry| registry.registered?(symbol) }
      end

      def root_type
        GLOBAL.type_registry.root_type
      end

      def type_registries
        accesses_up_hierarchy.map(&:type_registry)
      end

      def type_for_symbol(symbol)
        type_registries.each do |registry|
          if registry.registered?(symbol)
            return registry[symbol]
          end
        end
      end

      def accesses_up_hierarchy
        [self, *accesses, *accesses.map(&:accesses_up_hierarchy).flatten].uniq
      end

      # declaration handlers

      def register_type_declaration_handler(type_declaration_handler)
        type_declaration_handler_registry.register(type_declaration_handler)
      end

      def type_declaration_handler_registries
        accesses_up_hierarchy.map(&:type_declaration_handler_registry)
      end

      def type_declaration_handler_for(type_declaration)
        Namespace.using self do
          outcome = nil

          type_declaration_handler_registries.each do |registry|
            outcome = registry.processor_for(type_declaration)

            return outcome.result if outcome.success?
          end

          outcome.raise!
        end
      end

      def type_declaration_handler_for_handler_class(type_declaration_handler_class)
        type_declaration_handler_registries.each do |registry|
          registry.processors.each do |type_declaration_handler|
            if type_declaration_handler.instance_of?(type_declaration_handler_class)
              return type_declaration_handler
            end
          end
        end

        nil
      end

      def handlers
        type_declaration_handler_registries.map(&:handlers).flatten
      end

      def type_for_declaration(type_declaration)
        Namespace.using self do
          outcome = nil

          type_declaration_handler_registries.each do |registry|
            outcome = registry.process(type_declaration)

            return outcome.result if outcome.success?
          end

          outcome.raise!
        end
      end
    end
  end
end
