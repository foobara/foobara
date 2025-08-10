module Foobara
  class TypeDeclaration
    class << self
      def for(declaration)
        if declaration.is_a?(TypeDeclaration)
          declaration
        else
          unless declaration.is_a?(::Symbol) || declaration.is_a?(::String)
            declaration = case dup_depth
                          when nil
                            Util.deep_dup(declaration)
                          when 0
                            declaration
                          when 1
                            declaration.dup
                          end
          end

          new(declaration)
        end
      end
    end

    EMPTY_HASH = {}.freeze

    attr_accessor :reference, :declaration_hash

    # If passing in a reference it MUST be already absolutified
    def initialize(declaration_data)
      if declaration_data.is_a?(::Hash)
        self.declaration_hash = declaration_data
      else
        self.reference = declaration_data
      end
    end

    def reference?
      reference
    end

    def type
      reference || self[:type] || self["type"]
    end

    def method_missing(method_name, ...)
      if declaration_hash
        puts "hmmmm why would we do this??"
        TypeDeclaration.new(declaration_hash.send(method_name, ...))
      else
        h = { type: reference }
        result = h.send(method_name, ...)

        if h == { type: reference }
          TypeDeclaration.new(result)
        else
          self.declaration_hash = result
          self.reference = nil
          self
        end
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      super || EMPTY_HASH.respond_to?(method_name, include_private)
    end

    def to_reference_or_declaration
      reference || declaration_hash
    end
  end
end
