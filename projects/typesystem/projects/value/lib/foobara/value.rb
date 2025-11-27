require "foobara/domain"
require "foobara/common"

module Foobara
  module Value
    foobara_domain!
  end

  require_relative "../../src/processor"
end

Foobara.project("value", project_path: "#{__dir__}/../..")
