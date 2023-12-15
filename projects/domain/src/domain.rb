module Foobara
  module Domain
    class DomainAlreadyExistsError < StandardError; end

    class << self
      def create(full_domain_name)
        if Domain.to_domain(full_domain_name)
          raise DomainAlreadyExistsError, "Domain #{full_domain_name} already exists"
        end
      rescue Domain::NoSuchDomain
        begin
          Util.make_module(full_domain_name) { foobara_domain! }
        rescue Util::ParentModuleDoesNotExistError => e
          Util.make_module(e.parent_name) { foobara_organization! }
          Util.make_module(full_domain_name) { foobara_domain! }
        end
      end
    end
  end
end
