module Foobara
  class DomainMapper
    class << self
      def install!
        Namespace.global.foobara_add_category_for_subclass_of(:domain_mapper, self)
        Domain::DomainModuleExtension.include Foobara::DomainMapperLookups
      end
    end
  end
end
