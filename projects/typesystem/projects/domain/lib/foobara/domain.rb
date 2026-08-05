module Foobara
  module Domain
    class << self
      def install!
        if @installed
          # simplecov:disable
          raise "Already registered Domain"
          # simplecov:enable
        end

        # TODO: delete this?
        @installed = true

        Namespace.global.foobara_add_category(:organization) { is_a?(Module) && foobara_organization? }
        Namespace.global.foobara_add_category(:domain) { is_a?(Module) && foobara_domain? }
      end
    end
  end
end

Foobara.project("domain", project_path: "#{__dir__}/../..")
