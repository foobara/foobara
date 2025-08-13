module Foobara
  # Inheriting from ::Hash for now but we should remove this once all of the handlers are updated
  class TypeDeclaration
    attr_accessor :declaration_data,
                  :is_strict,
                  :is_strict_stringified,
                  :is_duped,
                  :is_deep_duped,
                  :is_absolutified

    def initialize(declaration_data)
      if TypeDeclarations.strict?
        self.is_strict = true
      elsif TypeDeclarations.strict_stringified?
        self.is_strict_stringified = true
      end

      self.declaration_data = declaration_data
    end

    def hash?
      declaration_data.is_a?(::Hash)
    end

    def key?(key)
      declaration_data.key?(key)
    end

    def [](key)
      declaration_data[key]
    end

    def proc? = declaration_data.is_a?(::Proc)
    def to_proc = declaration_data

    def []=(key, value)
      unless duped?
        self.declaration_data = declaration_data.dup
        self.is_duped = true
      end

      declaration_data[key] = value
    end

    def symbolize_keys!
      unless duped?
        self.declaration_data = declaration_data.dup
        self.is_duped = true
      end

      declaration_data.symbolize_keys!
    end

    def except(...) = declaration_data.except(...)
    def slice(...) = declaration_data.slice(...)

    def assign(other)
      self.declaration_data = other.declaration_data

      if strict? != other.strict?
        self.is_strict = other.strict?
      end

      if duped? != other.duped?
        self.is_duped = other.duped?
      end

      if absolutified? != other.absolutified?
        self.is_absolutified = other.absolutified?
      end

      if strict_stringified? != other.strict_stringified?
        self.is_strict_stringified = other.strict_stringified?
      end

      if deep_duped? != other.deep_duped?
        self.is_deep_duped = other.deep_duped?
      end
    end

    alias absolutified? is_absolutified
    alias duped? is_duped
    alias deep_duped? is_deep_duped
    alias strict? is_strict
    alias strict_stringified? is_strict_stringified
  end
end
