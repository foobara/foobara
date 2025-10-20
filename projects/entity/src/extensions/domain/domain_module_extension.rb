module Foobara
  module Domain
    module DomainModuleExtension
      module ClassMethods
        attr_reader :foobara_default_entity_base

        def foobara_set_entity_base(*, name: nil, prefix: nil)
          name ||= Util.underscore(scoped_full_name).gsub("::", "_")
          base = Persistence.register_base(*, name:, prefix:)
          @foobara_default_entity_base = base
        end
      end
    end
  end
end
