module Foobara
  module TypeDeclarations
    # TODO: this should instead be a processor and have its own possible_errors
    # TODO: does it make sense that this is in this project? Seems to be more generic than TypeDeclarations
    class TypedTransformer < Value::Transformer
      class << self
        def subclass(to: nil, from: nil, &map_proc)
          klass = Class.new(self)

          klass.to(to) if to
          klass.from(from) if from

          if map_proc
            if map_proc.arity.zero?
              klass.define_method(:transform) { |_ignored| map_proc.call }
            else
              klass.define_method(:transform, &map_proc)
            end
          end

          klass
        end

        def requires_declaration_data?
          false
        end

        def requires_parent_declaration_data?
          false
        end

        def from(...)
          @from_type = Domain.current.foobara_type_from_declaration(...)
        end

        def to(...)
          @to_type = Domain.current.foobara_type_from_declaration(...)
        end

        attr_reader :from_type, :to_type
      end

      def always_applicable?
        true
      end

      def from_type_declaration
        nil
      end

      def to_type_declaration
        nil
      end

      def from_type
        return @from_type if defined?(@from_type)

        @from_type = self.class.from_type || if from_type_declaration
                                               Domain.current.foobara_type_from_declaration(from_type_declaration)
                                             end
      end

      def to_type
        return @to_type if defined?(@to_type)

        @to_type = self.class.to_type || if to_type_declaration
                                           Domain.current.foobara_type_from_declaration(to_type_declaration)
                                         end
      end

      def has_to_type?
        !!to_type
      end

      def has_from_type?
        !!from_type
      end

      def from(...)
        @from_type = Domain.current.foobara_type_from_declaration(...)
      end

      def to(...)
        @to_type = Domain.current.foobara_type_from_declaration(...)
      end

      def initialize(from: nil, to: nil, **)
        super(**)

        if from
          self.from from
        end

        if to
          self.to to
        end

        # we want to force these to be created now in the current namespace if they are declarations
        from_type
        to_type
      end

      def process_value(value)
        if has_from_type?
          outcome = Namespace.use from_type.created_in_namespace do
            from_type.process_value(value)
          end

          return outcome unless outcome.success?

          value = outcome.result
        end

        output = transform(value)

        if has_to_type?
          Namespace.use to_type.created_in_namespace do
            to_type.process_value(output)
          end
        else
          Outcome.success(output)
        end
      end
    end
  end
end
