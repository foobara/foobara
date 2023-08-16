module Foobara
  module TypeDeclarations
    class ToTypeTransformer < Value::Transformer
      attr_accessor :type_registry, :type_declaration_handler_registry

      def initialize(
        *args,
        # TODO: potential problem... we cannot depend on BuiltinTypes here...
        type_registry: Types.global_registry,
        type_declaration_handler_registry: TypeDeclarations.global_type_declaration_handler_registry,
        **opts
      )
        # TODO: why aren't these just read off the declaration data and validated with a declaration_data_type??
        self.type_registry = type_registry
        self.type_declaration_handler_registry = type_declaration_handler_registry

        super(*Util.args_and_opts_to_args(args, opts))
      end

      def always_applicable?
        true
      end
    end
  end
end
