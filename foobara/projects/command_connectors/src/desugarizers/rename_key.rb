module Foobara
  module CommandConnectors
    module Desugarizers
      class << self
        def rename(sugar_name, official_name)
          class_name = [name, Util.classify(sugar_name)].join("::")

          Util.make_class(class_name, RenameKey).tap do |klass|
            klass.singleton_class.attr_accessor :sugar_name, :official_name
            klass.sugar_name = sugar_name
            klass.official_name = official_name
          end
        end
      end

      # TODO: Make this the default. Deprecate :inputs_transformers
      class RenameKey < Desugarizer
        class << self
          attr_accessor :sugar_name, :official_name
        end

        def applicable?(args_and_opts)
          _args, opts = args_and_opts
          opts.key?(sugar_name)
        end

        def sugar_name
          self.class.sugar_name
        end

        def official_name
          self.class.official_name
        end

        def desugarize(args_and_opts)
          rename(args_and_opts, sugar_name, official_name)
        end

        def priority
          Priority::HIGH
        end
      end
    end
  end
end
