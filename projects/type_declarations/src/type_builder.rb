require "foobara/lru_cache"

module Foobara
  module TypeDeclarations
    class << self
      # TODO: relocate these to a different file
      def args_to_type_declaration(*args, &block)
        if block
          if args.empty? || args == [:attributes]
            TypeDeclaration.new(block)
          elsif args == [:array]
            type_declaration = TypeDeclaration.new(type: :array, element_type_declaration: block)
            type_declaration.is_absolutified = true
            type_declaration.is_duped = true
            type_declaration.is_deep_duped = true
            type_declaration
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
            arg = args.first

            if arg.is_a?(TypeDeclaration)
              arg
            else
              TypeDeclaration.new(arg)
            end
          else
            type, *symbolic_processors, processor_data = args

            type_declaration = if !symbolic_processors.empty?
                                 symbolic_processors = symbolic_processors.to_h { |symbol| [symbol, true] }

                                 if processor_data.is_a?(::Hash) && !processor_data.empty?
                                   h = processor_data.merge(symbolic_processors)
                                   h[:type] = type
                                   TypeDeclaration.new(h)
                                 else
                                   type_declaration = TypeDeclaration.new(symbolic_processors.merge(type:))
                                   type_declaration.is_deep_duped = true
                                   type_declaration
                                 end
                               elsif processor_data.is_a?(::Hash)
                                 TypeDeclaration.new(processor_data.merge(type:))
                               else
                                 h = { type:, processor_data.to_sym => true }
                                 type_declaration = TypeDeclaration.new(h)
                                 type_declaration.is_deep_duped = true
                                 type_declaration
                               end

            type_declaration.is_duped = true
            type_declaration
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
              "No type declaration handler found for #{type_declaration.declaration_data}"
      end

      def handlers
        type_declaration_handler_registries.map(&:handlers).flatten.sort_by(&:priority)
      end

      def handler_for_class(klass)
        handlers.find { |handler| handler.instance_of?(klass) }
      end

      def type_for_strict_stringified_declaration(type_declaration)
        TypeDeclarations.strict_stringified do
          declaration = TypeDeclaration.new(type_declaration)
          handler = type_declaration_handler_for(declaration)
          handler.process_value!(declaration)
        end
      end

      def type_for_strict_declaration(type_declaration)
        TypeDeclarations.strict do
          declaration = TypeDeclaration.new(type_declaration)
          handler = type_declaration_handler_for(declaration)
          handler.process_value!(declaration)
        end
      end

      def type_for_declaration(*type_declaration_bits, &block)
        lru_cache.cached([self, *block&.object_id, *type_declaration_bits]) do
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

        type = type_declaration.type
        return type if type

        handler = type_declaration_handler_for(type_declaration)
        handler.process_value!(type_declaration)
      end

      private

      def lru_cache
        @lru_cache ||= Foobara::LruCache.new(100).tap do |cache|
          Namespace.on_change(cache, :reset!)
        end
      end
    end
  end
end
