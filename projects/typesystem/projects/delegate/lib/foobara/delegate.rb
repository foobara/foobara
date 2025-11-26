require "foobara/project"

module Foobara::Delegate; end

# TODO: we should just kill this project
Foobara.project("delegate", project_path: "#{__dir__}/../..")
