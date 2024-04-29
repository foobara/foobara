module Foobara
  module Domain
    class << self
      def install!
        if @installed
          # :nocov:
          raise "Already registered Domain"
          # :nocov:
        end

        # TODO: delete this?
        @installed = true

        Namespace.global.foobara_add_category(:organization) { is_a?(Module) && foobara_organization? }
        Namespace.global.foobara_add_category(:domain) { is_a?(Module) && foobara_domain? }
      end

      def reset_all
        if Foobara::DomainMapper.instance_variable_defined?(:@foobara_domain_mappers_to_process)
          Foobara::DomainMapper.remove_instance_variable(:@foobara_domain_mappers_to_process)
        end
      end
    end
  end
end
