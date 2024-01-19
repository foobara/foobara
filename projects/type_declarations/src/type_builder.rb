module Foobara
  module TypeDeclarations
    class TypeBuilder
      include TruncatedInspect

      class NoTypeDeclarationHandlerFoundError < StandardError; end

      class << self
        def new(...)
          super.tap do |instance|
            namespaces << instance
          end
        end

        def reset_all
          remove_instance_variable("@namespaces") if instance_variable_defined?("@namespaces")
        end

        def namespaces
          @namespaces ||= []
        end

        def current
          Thread.current[:foobara_namespace] || GlobalDomain.foobara_type_namespace
        end

        def using(namespace_or_symbol)
          namespace = if namespace_or_symbol.is_a?(TypeBuilder)
                        namespace_or_symbol
                      else
                        # :nocov:
                        raise ArgumentError, "Expected #{namespace_or_symbol} to be a symbol or namespace"
                        # :nocov:
                      end

          old_namespace = Thread.current[:foobara_namespace]

          begin
            Thread.current[:foobara_namespace] = namespace
            yield
          ensure
            Thread.current[:foobara_namespace] = old_namespace
          end
        end

        foobara_delegate :type_declaration_handler_registries,
                         :type_declaration_handler_for,
                         :type_declaration_handler_for_handler_class,
                         :handlers,
                         :type_for_declaration,
                         to: :current
      end

      attr_accessor :name, :type_declaration_handler_registry, :accesses

      def initialize(
        name,
        accesses: GlobalDomain.foobara_type_namespace,
        type_declaration_handler_registry: TypeDeclarations::TypeDeclarationHandlerRegistry.new(enforce_unique: false)
      )
        self.name = name
        self.type_declaration_handler_registry = type_declaration_handler_registry

        self.accesses = Util.array(accesses)
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
        # TODO: is it actually necessary to enter the namespace for this?
        TypeBuilder.using self do
          handlers.each do |handler|
            return handler if handler.applicable?(type_declaration)
          end

          raise NoTypeDeclarationHandlerFoundError,
                "No type declaration handler found for #{type_declaration}"
        end
      end

      def handlers
        type_declaration_handler_registries.map(&:handlers).flatten.sort_by(&:priority)
      end

      def handler_for_class(klass)
        handlers.find { |handler| handler.instance_of?(klass) }
      end

      def type_for_declaration(*type_declaration_bits)
        type_declaration = type_declaration_bits_to_type_declaration(type_declaration_bits)

        # TODO: is it actually necessary to enter the namespace for this?
        TypeBuilder.using self do
          handler = type_declaration_handler_for(type_declaration)
          handler.process_value!(type_declaration)
        end
      end

      def type_declaration_bits_to_type_declaration(type_declaration_bits)
        case type_declaration_bits.length
        when 0
          # :nocov:
          raise ArgumentError, "Expected a type declaration or type declaration bits, but 0 args given instead."
          # :nocov:
        when 1
          type_declaration_bits.first
        else
          type, *symbolic_processors, processor_data = type_declaration_bits

          if !symbolic_processors.empty?
            symbolic_processors = symbolic_processors.to_h { |symbol| [symbol, true] }

            if processor_data.is_a?(::Hash) && !processor_data.empty?
              processor_data.merge(symbolic_processors)
            else
              symbolic_processors
            end
          elsif processor_data.is_a?(::Hash)
            processor_data
          else
            { processor_data.to_sym => true }
          end.merge(type:)
        end
      end
    end
  end
end
