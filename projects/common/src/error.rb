module Foobara
  class Error < StandardError
    foobara_autoregister_subclasses(default_namespace: Foobara::GlobalDomain)

    include Manifestable

    # TODO: rename :path to data_path
    attr_accessor :error_key, :message, :context, :is_fatal

    # Need to do this early so doing it here... not sure if this is OK as it couples namespaces and errors

    class << self
      def abstract
        @abstract = true
      end

      def abstract?
        @abstract
      end

      def symbol
        Util.non_full_name_underscore(self).gsub(/_error$/, "").to_sym
      end

      def path
        ErrorKey::EMPTY_PATH
      end

      def runtime_path
        ErrorKey::EMPTY_PATH
      end

      def category
        nil
      end

      def message
        nil
      end

      def context
        nil
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

      def foobara_manifest(to_include:)
        types = types_depended_on.map do |t|
          to_include << t
          t.foobara_manifest_reference
        end

        base = nil
        # don't bother including these core errors
        unless superclass == Foobara::Error
          base = superclass
          to_include << base
        end

        manifest = super

        unless types.empty?
          manifest[:types_depended_on] = types.sort
        end

        h = manifest.merge(Util.remove_blank(to_h))

        if base
          h[:base_error] = base.foobara_manifest_reference
        end

        if abstract?
          h[:abstract] = true
        end

        h
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
      self.path = path
      self.runtime_path = runtime_path
      self.is_fatal = is_fatal

      if !self.message.is_a?(String) || self.message.empty?
        # :nocov:
        raise "Bad error message, expected a string"
        # :nocov:
      end

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
