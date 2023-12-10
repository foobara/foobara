module Foobara
  class Domain
    module DomainModuleExtension
      include Concern

      module ClassMethods
        def foobara_domain
          @foobara_domain ||= Domain.new(domain_name: Util.non_full_name(self), mod: self)
        end

        def foobara_domain?
          true
        end

        foobara_delegate :depends_on,
                         :type_for_declaration,
                         :register_entity,
                         :register_entities,
                         to: :foobara_domain
      end
    end
  end
end
