require "foobara/outcome"
require "foobara/util"

module Foobara
  class Model
    # A type contains the following key information about a "type"
    # * The Ruby class associated with this type which is the class of a value of this type
    # * The casters that can transform values of other types to a value of this type
    # * The validators that can optionally be applied to a value of this type
    # * The transformers that can optionally be applied to a value of this type
    # * unclear if needed, but mandatory validators and transformers
    #
    # how to handle attributes type??
    # Seems like it would require a custom caster/validator?
    # So it seems like an attributes type would be an instance of a type. So we can't use singletons like this
    # and need to go back to non-singletons. Primitives would have singletons. But Attributes can't.
    # They need to be initialized from outside using objects build from Schema objects.
    class Type
      class << self
        def instance
          @instance ||= new
        end
      end

      def caster
        @caster ||= begin
          Util.require_pattern("#{__dir__}/type/*/casters/*.rb")

          casters_module = Util.constant_value(self.class, :Casters)

          casters = casters_module ? Util.constant_values(casters_module, Class) : []
          # TODO: see if this passing of self can be eliminated
          direct_caster = Casters::DirectTypeMatchCaster.new(self)

          if casters.empty?
            direct_caster
          else
            CasterCollection.new(direct_caster, *casters.map(&:instance))
          end
        end
      end

      def cast_from(value)
        caster.cast_from(value)
      end

      def ruby_class
        @ruby_class ||= Object.const_get(self.class.name.demodulize)
      end

      def symbol
        @symbol ||= self.class.name.demodulize.underscore.to_sym
      end

      # Do we really need this method?
      def can_cast?(value)
        cast_from(value).success?
      end

      # Do we really need this method?
      def casting_errors(value)
        cast_from(value).errors
      end

      # Do we really need this method?
      def cast_from!(value)
        outcome = cast_from(value)

        if outcome.success?
          outcome.result
        else
          outcome.raise!
        end
      end

      def validation_errors(_value)
        # TODO: override this in relevant base types
        []
      end
    end
  end
end
