require "foobara/util"

module Foobara
  class Project; end
end

Foobara::Util.require_directory "#{__dir__}/../../src"

Foobara.project("project", project_path: "#{__dir__}/../..")
