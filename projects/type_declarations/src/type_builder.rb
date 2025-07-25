require "foobara/lru_cache"

module Foobara
  module TypeDeclarations
    class << self
      # TODO: relocate these to a different file
      def args_to_type_declaration(*args, &block)
        if block
          if args.empty? || args == [:attributes]
            block
          elsif args == [:array]
            { type: :array, element_type_declaration: block }
          else
            # :nocov:
            raise ArgumentError, "Cannot provide both block and declaration of #{args}"
            # :nocov:
          end
        else
          case args.size
          when 0
            # :nocov:
            raise ArgumentError, "expected 1 argument or a block but got 0 arguments and no block"
            # :nocov:
          when 1
            args.first
          else
            type, *symbolic_processors, processor_data = args

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

      def type_for_strict_stringified_declaration(type_declaration)
        TypeDeclarations.strict_stringified do
          handler = type_declaration_handler_for(type_declaration)
          handler.process_value!(type_declaration)
        end
      end

      def type_for_strict_declaration(type_declaration)
        TypeDeclarations.strict do
          handler = type_declaration_handler_for(type_declaration)
          handler.process_value!(type_declaration)
        end
      end

      def type_for_declaration(*type_declaration_bits, &block)
        lru_cache.cached([type_declaration_bits, block]) do
          type_for_declaration_without_cache(*type_declaration_bits, &block)
        end
      rescue NoTypeDeclarationHandlerFoundError
        raise if TypeDeclarations.strict_stringified?
        raise if TypeDeclarations.stringified?
        raise if TypeDeclarations.strict?

        TypeDeclarations.stringified do
          type_for_declaration(*type_declaration_bits, &block)
        end
      end

      def type_for_declaration_without_cache(*type_declaration_bits, &)
        type_declaration = TypeDeclarations.args_to_type_declaration(*type_declaration_bits, &)

        handler = type_declaration_handler_for(type_declaration)
        handler.process_value!(type_declaration)
      end

      def clear_cache
        if @lru_cache
          lru_cache.reset!
        end
      end

      private

      def lru_cache
        @lru_cache ||= Foobara::LruCache.new(100)
      end
    end
  end
end
