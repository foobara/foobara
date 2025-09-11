module Foobara
  class Error < StandardError
    foobara_autoregister_subclasses(default_namespace: Foobara::GlobalDomain)

    include Manifestable

    # TODO: rename :path to data_path
    attr_accessor :error_key, :message, :context, :is_fatal, :backtrace_when_initialized, :backtrace_when_raised

    # Need to do this early so doing it here... not sure if this is OK as it couples namespaces and errors

    class << self
      def abstract
        @abstract = true
      end

      def abstract?
        @abstract
      end

      def symbol(*args)
        args_size = args.size

        case args_size
        when 0
          Util.non_full_name_underscore(self).gsub(/_error$/, "").to_sym
        when 1
          arg = args.first
          singleton_class.define_method :symbol do
            arg
          end
        else
          # :nocov:
          raise ArgumentError, "expected 0 or 1 argument, got #{args_size}"
          # :nocov:
        end
      end

      # Is this actually used?
      def path
        ErrorKey::EMPTY_PATH
      end

      def runtime_path
        ErrorKey::EMPTY_PATH
      end

      def category
        nil
      end

      def message(*args)
        args_size = args.size

        case args_size
        when 0
          Util.humanize(symbol.to_s)
        when 1
          arg = args.first
          singleton_class.define_method :message do
            arg
          end
        else
          # :nocov:
          raise ArgumentError, "expected 0 or 1 argument, got #{args_size}"
          # :nocov:
        end
      end

      def context(*args, &block)
        if block_given?
          args = [*args, block]
        end
        args_size = args.size

        case args_size
        when 0
          {}
        when 1
          arg = args.first
          singleton_class.define_method :context_type_declaration do
            arg
          end
        else
          # :nocov:
          raise ArgumentError, "expected 0 or 1 argument, got #{args_size}"
          # :nocov:
        end
      end

      def fatal?
        false
      end

      def to_h
        {
          category:,
          symbol:,
          # TODO: this is a bad dependency direction but maybe time to bite the bullet and finally merge these...
          context_type_declaration: context_type&.declaration_data,
          is_fatal: fatal?
        }
      end

      def foobara_manifest
        to_include = TypeDeclarations.foobara_manifest_context_to_include

        types = types_depended_on.map do |t|
          if to_include
            to_include << t
          end
          t.foobara_manifest_reference
        end

        base = nil
        # don't bother including these core errors
        unless superclass == Foobara::Error
          base = superclass
          if to_include
            to_include << base
          end
        end

        manifest = super

        unless types.empty?
          manifest[:types_depended_on] = types.sort
        end

        h = manifest.merge(Util.remove_blank(to_h)).merge(
          error_class: name
        )

        if base
          h[:base_error] = base.foobara_manifest_reference
        end

        if abstract?
          h[:abstract] = true
        end

        h
      end

      def subclass(
        # TODO: technically context doesn't belong here. But maybe it should.
        context: {},
        name: nil,
        symbol: nil,
        message: nil,
        base_error: self,
        mod: base_error,
        category: base_error.category,
        is_fatal: false,
        abstract: false
      )
        name ||= [*mod.name, "#{Util.classify(symbol)}Error"].join("::")

        klass = Util.make_class_p(name, base_error) do
          singleton_class.define_method :category do
            category
          end

          if symbol
            singleton_class.define_method :symbol do
              symbol
            end
          end

          singleton_class.define_method :fatal? do
            is_fatal
          end

          singleton_class.define_method :context_type_declaration do
            context
          end

          if message
            singleton_class.define_method :message do
              message
            end
          end
        end

        klass.abstract if abstract

        klass
      end
    end

    foobara_delegate :runtime_path,
                     :runtime_path=,
                     :category,
                     :category=,
                     :path,
                     :path=,
                     :symbol,
                     :symbol=,
                     to: :error_key

    # TODO: seems like we should not allow the symbol to vary within instances of a class
    # TODO: any items serializable in self.class.to_h should not be overrideable like this...
    def initialize(
      path: self.class.path,
      runtime_path: self.class.runtime_path,
      category: self.class.category,
      message: self.class.message,
      symbol: self.class.symbol,
      context: self.class.context,
      is_fatal: self.class.fatal?
    )
      self.error_key = ErrorKey.new

      self.symbol = symbol
      self.message = message
      self.context = context
      self.category = category

      if path.is_a?(::String) || path.is_a?(::Symbol)
        path = path.to_s.split(".").map(&:to_sym)
      end

      self.path = path
      self.runtime_path = runtime_path
      self.is_fatal = is_fatal

      if !self.message.is_a?(String) || self.message.empty?
        # :nocov:
        raise "Bad error message, expected a string"
        # :nocov:
      end

      backtrace_when_initialized = caller[1..]
      index = 1

      has_build_error = false

      1.upto(10) do |i|
        backtrace_line = backtrace_when_initialized[i]

        break unless backtrace_line

        if backtrace_when_initialized[i].end_with?("#build_error'")
          index = i + 1
          has_build_error = true
          break
        end
      end

      if has_build_error
        index.upto(10) do |i|
          unless backtrace_when_initialized[i].end_with?("#build_error'")
            index = i
            break
          end
        end
      end

      self.backtrace_when_initialized = backtrace_when_initialized[index..]

      super(message)
    end

    def fatal?
      is_fatal
    end

    def key
      error_key.to_s
    end

    def ==(other)
      equal?(other) || eql?(other)
    end

    def eql?(other)
      return false unless other.is_a?(Error)

      symbol == other.symbol
    end

    def prepend_path!(...)
      error_key.prepend_path!(...)
      self
    end

    def to_h
      {
        key:,
        path:,
        runtime_path:,
        category:,
        symbol:,
        message:,
        context:,
        is_fatal: fatal?
      }
    end
  end
end
