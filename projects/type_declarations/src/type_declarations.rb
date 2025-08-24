require "inheritable_thread_vars"

module Foobara
  require_project_file("type_declarations", "type_builder")
  require_project_file("type_declarations", "error_extension")

  module TypeDeclarations
    module Mode
      STRICT = :strict
      STRICT_STRINGIFIED = :strict_stringified
      STRINGIFIED = :stringified
    end

    class << self
      def global_type_declaration_handler_registry
        GlobalDomain.foobara_type_builder.type_declaration_handler_registry
      end

      def register_type_declaration(type_declaration_handler)
        global_type_declaration_handler_registry.register(type_declaration_handler)
      end

      def register_sensitive_type_remover(sensitive_type_remover)
        handler = sensitive_type_remover.handler
        sensitive_type_removers[handler.class.name] = sensitive_type_remover
      end

      def sensitive_type_removers
        @sensitive_type_removers ||= {}
      end

      def remove_sensitive_types(strict_type_declaration)
        declaration = TypeDeclaration.new(strict_type_declaration)
        declaration.is_strict = true

        handler = GlobalDomain.foobara_type_builder.type_declaration_handler_for(declaration)

        sensitive_type_remover = sensitive_type_removers[handler.class.name]

        if sensitive_type_remover&.applicable?(strict_type_declaration)
          sensitive_type_remover.process_value!(strict_type_declaration)
        else
          strict_type_declaration
        end
      end

      # TODO: since these are dealing with values instead of declarations maybe this should live somewhere else?
      def register_sensitive_value_remover(handler, sensitive_value_remover)
        sensitive_value_removers[handler.class.name] = sensitive_value_remover
      end

      def sensitive_value_removers
        @sensitive_value_removers ||= {}
      end

      def sensitive_value_remover_class_for_type(type)
        declaration_data = type.declaration_data
        declaration = TypeDeclaration.new(declaration_data)
        declaration.is_strict = true

        handler = GlobalDomain.foobara_type_builder.type_declaration_handler_for(declaration)
        remover_class = sensitive_value_removers[handler.class.name]

        unless remover_class
          # :nocov:
          raise "No sensitive value remover found for #{declaration_data}"
          # :nocov:
        end

        remover_class
      end

      def strict(&)
        using_mode(Mode::STRICT, &)
      end

      def strict_stringified(&)
        using_mode(Mode::STRICT_STRINGIFIED, &)
      end

      def stringified(&)
        using_mode(Mode::STRINGIFIED, &)
      end

      # TODO: use manifest context instead
      def using_mode(new_mode, &)
        with_manifest_context(mode: new_mode, &)
      end

      def strict?
        foobara_manifest_context_mode == Mode::STRICT
      end

      def strict_stringified?
        foobara_manifest_context_mode == Mode::STRICT_STRINGIFIED
      end

      def stringified?
        foobara_manifest_context_mode == Mode::STRINGIFIED || strict_stringified?
      end

      def include_processors?
        foobara_manifest_context_include_processors?
      end

      # TODO: we should desugarize these but can't because of a bug where desugarizing entities results in creating the
      # entity class in memory, whoops.
      def declarations_equal?(declaration1, declaration2)
        declaration1 = declaration1.reject { |(k, _v)| k.to_s.start_with?("_") }.to_h
        declaration2 = declaration2.reject { |(k, _v)| k.to_s.start_with?("_") }.to_h

        declaration1 == declaration2
      end

      def foobara_manifest_context
        Thread.inheritable_thread_local_var_get("foobara_manifest_context")
      end

      allowed_context_keys = [:detached, :to_include, :mode, :remove_sensitive, :include_processors]
      booleans = [:detached, :remove_sensitive, :include_processors]

      booleans.each do |context_item|
        define_method "foobara_manifest_context_#{context_item}?" do
          !!foobara_manifest_context&.[](context_item)
        end
      end

      (allowed_context_keys - booleans).each do |context_item|
        define_method "foobara_manifest_context_#{context_item}" do
          foobara_manifest_context&.[](context_item)
        end
      end

      def manifest_context_set?(context_item)
        foobara_manifest_context&.key?(context_item)
      end

      def with_manifest_context(context)
        old_context = foobara_manifest_context
        begin
          new_context = (old_context || {}).merge(context)
          Thread.inheritable_thread_local_var_set("foobara_manifest_context", new_context)
          yield
        ensure
          Thread.inheritable_thread_local_var_set("foobara_manifest_context", old_context)
        end
      end
    end
  end
end
