require "active_support/core_ext/object/deep_dup"

Foobara::Util.require_directory("#{__dir__}/model")

module Foobara
  class Model
    Schema.register_schema(Schema::Duck)
    Schema.register_schema(Schema::Symbol)
    Schema.register_schema(Schema::Integer)
    Schema.register_schema(Schema::Attributes)
  end
end

# Here we are adding extensions to Foobara::Type but probably a better approach is to
# combine and couple the two projects. Going to keep this separated for now though to
# try to benefit from the separation of concerns longer but should someday merge these projects.
# TODO: merge these projects
Foobara::Type::AttributeError.class_eval do
  class << self
    def context_schema
      {
        path: :duck, # TODO: fix this up once there's an array type
        attribute_name: :symbol,
        value: :duck
      }
    end
  end

  delegate :context_schema, to: :class
end
