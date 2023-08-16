module Foobara
  module TypeDeclarations
    module WithRegistries
      attr_accessor :type_registry, :type_declaration_handler_registry

      def initialize(
        *args,
        type_registry: Types.global_registry,
        type_declaration_handler_registry: TypeDeclarations.global_type_declaration_handler_registry,
        **opts
      )
        # TODO: why aren't these just read off the declaration data and validated with a declaration_data_type??
        self.type_registry = type_registry
        self.type_declaration_handler_registry = type_declaration_handler_registry

        super(*Util.args_and_opts_to_args(args, opts))
      end
    end
  end
end
