require "foobara/util"

module Foobara
  class Project; end
end

Foobara::Util.require_directory "#{__dir__}/../../src"

# Do we need this to be a project??
Foobara.project("project", project_path: "#{__dir__}/../..")
