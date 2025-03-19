module Foobara
  module Value
    class Processor
      foobara_subclasses_are_namespaces!(default_parent: GlobalDomain, autoregister: true)
      # Do we really need both to be namespaces??
      foobara_instances_are_namespaces!(default_parent: GlobalDomain)

      include Manifestable
      include IsManifestable

      module Priority
        FIRST = 0
        HIGH = 10
        MEDIUM = 20
        LOW = 30
        LOWEST = 40
      end

      class << self
        def processor_name
          name || "Anonymous"
        end

        def default_declaration_data
          true
        end

        def foobara_manifest(to_include: Set.new, remove_sensitive: false)
          errors = error_classes.map do |error_class|
            to_include << error_class
            error_class.foobara_manifest_reference
          end

          manifest = super.merge(
            name: processor_name,
            processor_type: :processor
          )

          unless errors.empty?
            manifest[:error_classes] = errors.sort
          end

          manifest
        end

        def new_with_agnostic_args(**rest)
          allowed_keys = %i[declaration_data parent_declaration_data]

          invalid_keys = rest.keys - allowed_keys

          unless invalid_keys.empty?
            # :nocov:
            raise ArgumentError, "Invalid keys: #{invalid_keys.join(", ")} expected one of #{allowed_keys.join(", ")}"
            # :nocov:
          end

          args = []

          if requires_declaration_data?
            args << if rest.key?(:declaration_data)
                      rest[:declaration_data]
                    else
                      default_declaration_data
                    end
          end

          if requires_parent_declaration_data?
            args << rest[:parent_declaration_data] if requires_parent_declaration_data?
          end

          if args.empty? || args == [default_declaration_data]
            instance
          else
            # TODO: This feels goofy that the positional types of this interface is dependent on these flags...
            new(*args)
          end
        end

        def instance
          @instance ||= begin
            if requires_parent_declaration_data?
              # :nocov:
              raise "Cannot treat processors dependent on parent declaration data as singletons"
              # :nocov:
            end

            requires_declaration_data? ? new(default_declaration_data) : new
          end
        end

        def error_classes
          @error_classes ||= begin
            error_klasses = Util.constant_values(self, extends: Foobara::Error)

            # TODO: we shouldn´t have wo ways to do this. But keeping this check for now until the old
            # namespace implementation is removed.
            error_klasses2 = if is_a?(Foobara::Namespace::IsNamespace)
                               foobara_all_error(mode: Namespace::LookupMode::DIRECT)
                             end

            if error_klasses.sort_by(&:name) != error_klasses2.sort_by(&:name)
              # :nocov:
              raise "Expected #{error_klasses} to equal #{error_klasses2} for #{name}"
              # :nocov:
            end

            if superclass < Processor
              error_klasses2 += superclass.error_classes
            end

            error_klasses2
          end
        end

        def error_class
          return @error_class if defined?(@error_class)

          unless error_classes.size == 1
            # :nocov:
            raise "Expected exactly one error class to be defined for #{name} but has #{error_classes.size}"
            # :nocov:
          end

          @error_class = error_classes.first
        end

        def symbol
          @symbol ||= Util.non_full_name_underscore(self)&.gsub(/_(processor|transformer|validator)$/, "")&.to_sym
        end

        def requires_declaration_data?
          true
        end

        def requires_parent_declaration_data?
          false
        end
      end

      attr_accessor :declaration_data, :parent_declaration_data
      attr_writer :created_in_namespace

      def initialize(*args)
        # TODO: get this out of here somehow?
        unless Foobara::Namespace.current == Foobara
          self.created_in_namespace = Foobara::Namespace.current
        end

        expected_arg_count = requires_declaration_data? ? 1 : 0
        expected_arg_count += 1 if requires_parent_declaration_data?

        unless expected_arg_count == args.count
          # :nocov:
          raise ArgumentError, "#{name} expected #{expected_arg_count} received #{args.count}"
          # :nocov:
        end

        if requires_declaration_data?
          self.declaration_data = args.shift
        end

        if requires_parent_declaration_data?
          self.parent_declaration_data = args.first
        end
      end

      def created_in_namespace
        # TODO: can we find a way to not depend on domains in this project?
        @created_in_namespace ||= GlobalDomain
      end

      def name
        self.class.processor_name
      end

      foobara_delegate :error_class,
                       :error_classes,
                       :symbol,
                       :requires_declaration_data?,
                       :requires_parent_declaration_data?,
                       to: :class

      # Whoa, forgot this existed. Shouldn't we use this more?
      def runner(value)
        self.class::Runner.new(self, value)
      end

      # TODO: probably actually better to pass it through to the error class method. Bring that back.
      def error_message(_value)
        error_class.message
      end

      def error_context(_value)
        error_class.context
      end

      def possible_errors
        Foobara::Namespace.use created_in_namespace do
          error_classes.map do |error_class|
            PossibleError.new(error_class, processor: self)
          end
        end
      end

      # A transformer with no declaration data or with declaration data of false is considered to be
      # not applicable. Override this wherever different behavior is needed.
      def applicable?(_value)
        always_applicable?
      end

      # This means it's applicable regardless of value to transform. Override if different behavior is needed.
      def always_applicable?
        !!declaration_data
      end

      def process_value(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def process_value!(value)
        process_value(value).result!
      end

      def process_outcome(old_outcome)
        return old_outcome if old_outcome.fatal?

        value = old_outcome.result

        return old_outcome unless applicable?(value)

        process_value(value).tap do |outcome|
          outcome.add_errors(old_outcome.errors)
        end
      end

      def process_outcome!(old_outcome)
        process_outcome(old_outcome).result!
      end

      def build_error(
        value = nil,
        error_class: self.error_class,
        symbol: error_class.symbol,
        message: error_message(value),
        context: error_context(value),
        path: error_path,
        **
      )
        unless error_classes.include?(error_class)
          # :nocov:
          raise "invalid error"
          # :nocov:
        end

        error_class.new(
          path:,
          message:,
          context:,
          symbol:,
          **
        )
      end

      # TODO: does this make sense to have something called attribute_name here??
      def error_path
        Util.array(attribute_name)
      end

      # TODO: this is a bit problematic. Maybe eliminate this instead of assuming it's generally useful
      def attribute_name
        nil
      end

      # Helps control when it runs in a pipeline
      def priority
        Priority::MEDIUM
      end

      def dup_processor(**opts)
        valid_opts = %i[declaration_data parent_declaration_data]

        invalid_opts = opts.keys - valid_opts

        unless invalid_opts.empty?
          # :nocov:
          raise ArgumentError, "Invalid opts #{invalid_opts.inspect} expected only #{valid_opts.inspect}"
          # :nocov:
        end

        declaration_data = if opts.key?(:declaration_data)
                             opts[:declaration_data]
                           else
                             self.declaration_data
                           end
        parent_declaration_data = if opts.key?(:parent_declaration_data)
                                    opts[:parent_declaration_data]
                                  else
                                    self.parent_declaration_data
                                  end

        self.class.new_with_agnostic_args(declaration_data:, parent_declaration_data:)
      end

      def inspect
        s = super

        if s.size > 400
          # :nocov:
          s = "#{s[0..400]}..."
          # :nocov:
        end

        s
      end

      # TODO: is this in the wrong place? Should this be an extension?

      def foobara_manifest(to_include: Set.new, remove_sensitive: false)
        possible_errors = self.possible_errors.map do |possible_error|
          [possible_error.key.to_s, possible_error.foobara_manifest(to_include:)]
        end

        manifest = super.dup

        if scoped_category == :processor
          to_include << self.class
          manifest[:processor_class] = self.class.foobara_manifest_reference
        end

        if requires_declaration_data?
          manifest[:declaration_data] = declaration_data
        end

        unless possible_errors.empty?
          manifest[:possible_errors] = possible_errors.sort.to_h
        end

        manifest
      end

      def method_missing(method, *args, **opts)
        if method == symbol
          declaration_data
        else
          # :nocov:
          super
          # :nocov:
        end
      end

      def respond_to_missing?(method, private = false)
        method == symbol || super
      end
    end
  end
end
