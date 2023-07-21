module Foobara
  class Model
=begin
    class << self
      def global_registry
        @global_registry ||= Registry.new
      end

      delegate :register_type, :type_for, :type_symbol?, to: :global_registry
    end

    # TODO: make this not necessary!
    Util.require_pattern("#{__dir__}/model/type/*.rb")

    register_type(Type::Integer)
    register_type(Type::Attributes)
    register_type(Type::Duck)

=end

    # TODO: make this not necessary!
    Util.require_pattern("#{__dir__}/model/*_schema.rb")
    Schema.register_schema(IntegerSchema)
    Schema.register_schema(DuckSchema)
    Schema.register_schema(AttributesSchema)
  end
end
