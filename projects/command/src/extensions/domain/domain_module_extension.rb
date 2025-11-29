module Foobara
  module Domain
    module DomainModuleExtension
      module ClassMethods
        def foobara_command_classes
          foobara_all_command(mode: Namespace::LookupMode::DIRECT)
        end

        def foobara_can_call_subcommands_from?(other_domain)
          other_domain = Domain.to_domain(other_domain)
          other_domain == self || self == GlobalDomain || foobara_depends_on?(other_domain)
        end
      end
    end
  end
end
