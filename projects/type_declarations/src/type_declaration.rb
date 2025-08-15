module Foobara
  # Inheriting from ::Hash for now but we should remove this once all of the handlers are updated
  class TypeDeclaration
    attr_accessor :declaration_data,
                  :is_strict,
                  :is_strict_stringified,
                  :is_duped,
                  :is_deep_duped,
                  :is_absolutified,
                  :type

    def initialize(declaration_data)
      if TypeDeclarations.strict?
        self.is_strict = true
        self.is_absolutified = true
      elsif TypeDeclarations.strict_stringified?
        self.is_strict_stringified = true
        self.is_absolutified = true
      end

      if declaration_data == :duck
        binding.pry if strict?
      end

      self.declaration_data = declaration_data
    end

    def is_strict=(value)
      if value
        if declaration_data == :duck
          binding.pry
        end
        self.is_absolutified = true
      elsif absolutified?
        self.is_absolutified = false
      end

      @is_strict = value
    end

    def is_absolutified=(value)
      if value
        if proc?
          binding.pry
        end
        if declaration_data == :duck
          binding.pry
        end
      end
      @is_absolutified = value
    end

    def is_strict_stringified=(value)
      if value
        self.is_absolutified = true
      elsif absolutified?
        self.is_absolutified = false
      end

      @is_strict_stringified = value
    end

    def declaration_data=(value)
      if value.is_a?(::Hash) && value[:attributes_declaration].is_a?(TypeDeclaration)
        binding.pry
        raise "wtf"
      end
      if value == :duck
        binding.pry if strict?
      end

      if declaration_data == :duck
        binding.pry if strict?
      end

      if value.is_a?(TypeDeclaration)
        binding.pry
        raise "wtf"
      end

      if value.is_a?(::Proc) && absolutified?
        binding.pry
      end

      if declaration_data == :duck
        binding.pry if strict?
      end

      if value == declaration_data
        binding.pry if strict?
      end

      @declaration_data = value
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

    def symbol?
      declaration_data.is_a?(::Symbol)
    end

    def string?
      declaration_data.is_a?(::String)
    end

    def array?
      declaration_data.is_a?(::Array)
    end

    def proc?
      declaration_data.is_a?(::Proc)
    end

    def to_proc
      declaration_data
    end

    def size
      declaration_data.size
    end

    def empty?
      declaration_data.empty?
    end

    def delete(key)
      return unless declaration_data.key?(key)

      if declaration_data == :duck
        binding.pry if strict?
      end

      if duped?
        declaration_data.delete(key)
      else
        self.declaration_data = declaration_data.except(key)
        self.is_duped = true
      end

      if strict?
        self.is_strict = false
      end

      if absolutified? && key == :type
        self.is_absolutified = false
      end

      if declaration_data == :duck
        binding.pry if strict?
      end
    end

    def class?
      declaration_data.is_a?(::Class)
    end

    def type?
      declaration_data.is_a?(Types::Type)
    end

    def []=(key, value)
      if value.is_a?(TypeDeclaration)
        binding.pry
        raise "wtf"
      end
      if declaration_data == :duck
        binding.pry if strict?
      end

      binding.pry if declaration_data[key] == value && strict?

      if strict?
        self.is_strict = false
      end

      unless duped?
        self.declaration_data = declaration_data.dup
        self.is_duped = true
      end

      declaration_data[key] = value

      if declaration_data == :duck
        binding.pry if strict?
      end
    end

    def all_symbolizable_keys?
      Util.all_symbolizable_keys?(declaration_data)
    end

    def symbolize_keys!
      if duped?
        declaration_data.transform_keys!(&:to_sym)
      else
        self.declaration_data = declaration_data.transform_keys(&:to_sym)
        self.is_duped = true
      end

      self
    end

    def except(...)
      parts = declaration_data.except(...)

      declaration = clone_from_part(parts)
      declaration.is_duped = true

      if declaration.strict?
        declaration.is_strict = false
      end

      if declaration.strict_stringified?
        declaration.is_strict_stringified = false
      end

      declaration
    end

    def slice(...)
      parts = declaration_data.slice(...)

      declaration = clone_from_part(parts)
      declaration.is_duped = true

      if declaration.strict?
        declaration.is_strict = false
      end

      if declaration.strict_stringified?
        declaration.is_strict_stringified = false
      end

      declaration
    end

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

      if other.type
        self.type = other.type
      end

      if declaration_data == :duck
        binding.pry if strict?
      end
    end

    def clone
      declaration = TypeDeclaration.new(declaration_data)

      if strict?
        declaration.is_strict = true
      end

      if strict_stringified?
        declaration.is_strict_stringified = true
      end

      if absolutified?
        declaration.is_absolutified = true
      end

      if type
        declaration.type = type
      end

      if declaration_data == :duck
        binding.pry if strict?
      end

      declaration
    end

    def clone_from_part(part)
      declaration = TypeDeclaration.new(part)

      if strict?
        declaration.is_strict = true
      end

      if strict_stringified?
        declaration.is_strict_stringified = true
      end

      declaration
    end

    alias absolutified? is_absolutified
    alias duped? is_duped
    alias deep_duped? is_deep_duped
    alias strict? is_strict
    alias strict_stringified? is_strict_stringified
  end
end
