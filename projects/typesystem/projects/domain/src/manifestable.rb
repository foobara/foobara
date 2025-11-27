require_relative "is_manifestable"
require "foobara/concerns"

module Foobara
  # Weird that this concept lives here instead of in its own project...
  module Manifestable
    include Concern

    module ClassMethods
      include IsManifestable
    end
  end
end
