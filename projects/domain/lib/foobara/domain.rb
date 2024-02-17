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

        Foobara.foobara_add_category(:organization) { is_a?(Module) && foobara_organization? }
        Foobara.foobara_add_category(:domain) { is_a?(Module) && foobara_domain? }
      end
    end
  end
end
