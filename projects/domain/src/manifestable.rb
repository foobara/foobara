require_relative "is_manifestable"

module Foobara
  module Manifestable
    include Concern

    module ClassMethods
      include IsManifestable
    end
  end
end
