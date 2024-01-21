module Foobara
  module TypeDeclarations
    class TypeBuilder
      class NoTypeDeclarationHandlerFoundError < StandardError; end

      include TruncatedInspect

      attr_accessor :name, :type_declaration_handler_registry, :accesses

      def initialize(
        name,
        accesses: GlobalDomain.foobara_type_builder,
        type_declaration_handler_registry: TypeDeclarations::TypeDeclarationHandlerRegistry.new
      )
        self.name = name
        self.type_declaration_handler_registry = type_declaration_handler_registry
        self.accesses = Util.array(accesses).to_set
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
        handlers.each do |handler|
          return handler if handler.applicable?(type_declaration)
        end

        raise NoTypeDeclarationHandlerFoundError,
              "No type declaration handler found for #{type_declaration}"
      end

      def handlers
        type_declaration_handler_registries.map(&:handlers).flatten.sort_by(&:priority)
      end

      def handler_for_class(klass)
        handlers.find { |handler| handler.instance_of?(klass) }
      end

      def type_for_declaration(*type_declaration_bits, &block)
        type_declaration = if block
                             unless type_declaration_bits.empty?
                               # :nocov:
                               raise ArgumentError, "Cannot provide both block and declaration"
                               # :nocov:
                             end

                             block
                           else
                             case type_declaration_bits.size
                             when 0
                               # :nocov:
                               raise ArgumentError, "expected 1 argument or a block but got 0 arguments and no block"
                               # :nocov:
                             when 1
                               declaration = type_declaration_bits.first

                               return declaration if declaration.is_a?(Types::Type)

                               declaration
                             else
                               type_declaration_bits_to_type_declaration(type_declaration_bits)
                             end
                           end

        handler = type_declaration_handler_for(type_declaration)
        handler.process_value!(type_declaration)
      end

      private

      def type_declaration_bits_to_type_declaration(type_declaration_bits)
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
