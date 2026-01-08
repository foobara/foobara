module Foobara
  # Inheriting from ::Hash for now but we should remove this once all of the handlers are updated
  class TypeDeclaration
    attr_reader :is_strict

    attr_accessor :is_duped,
                  :declaration_data,
                  :is_deep_duped,
                  :is_absolutified,
                  :reference_checked,
                  :type,
                  :base_type

    # TODO: we should be able to delete absolutified opt once strict declarations
    # use `:ref` instead of `{type: :ref}` format.
    def initialize(declaration_data, absolutified = false, skip_reference_check = false)
      if TypeDeclarations.strict?
        self.is_strict = true
      elsif absolutified || TypeDeclarations.strict_stringified?
        self.is_absolutified = true
      end

      self.declaration_data = declaration_data

      unless strict? || skip_reference_check
        handle_symbolic_declaration
      end
    end

    def is_strict=(value)
      if value
        self.is_absolutified = true
      end

      @is_strict = value
    end

    def handle_symbolic_declaration
      self.reference_checked = true

      symbol = if declaration_data.is_a?(::Symbol)
                 declaration_data
               elsif declaration_data.is_a?(::String)
                 declaration_data.to_sym
               end

      if symbol
        mode = if absolutified?
                 Namespace::LookupMode::ABSOLUTE
               else
                 Namespace::LookupMode::RELAXED
               end

        type = Domain.current.foobara_lookup_type(symbol, mode:)

        if type
          unless strict?
            self.declaration_data = type.full_type_symbol
          end

          self.type = type

          self.is_strict = true
          self.is_deep_duped = true
          self.is_duped = true
        else
          if declaration_data.is_a?(::Symbol)
            self.is_duped = true
            self.is_deep_duped = true
          end

          self.declaration_data = declaration_data
        end
      elsif TypeDeclarations.strict_stringified?
        symbolize_keys!
        type_symbol = self[:type].to_sym
        self[:type] = type_symbol

        type = Domain.current.foobara_lookup_type(type_symbol, mode: Namespace::LookupMode::ABSOLUTE)

        if type
          if declaration_data.keys.size == 1
            self.type = type
            self.is_strict = true
            self.is_deep_duped = true
            self.is_duped = true
            self.declaration_data = type.full_type_symbol
          else
            self.base_type = type
          end
        end
      elsif declaration_data.is_a?(::Hash)
        type_symbol = self[:type] || self["type"]

        if type_symbol
          if type_symbol.is_a?(::Symbol) || type_symbol.is_a?(::String)
            mode = if absolutified?
                     Namespace::LookupMode::ABSOLUTE
                   else
                     Namespace::LookupMode::RELAXED
                   end

            type = Domain.current.foobara_lookup_type(type_symbol, mode:)

            if type
              symbolize_keys!
              self[:type] = type.full_type_symbol
              self.is_absolutified = true

              if declaration_data.keys.size == 1
                self.declaration_data = type.full_type_symbol

                self.type = type
                self.is_strict = true
                self.is_deep_duped = true
              else
                self.base_type = type
              end
            end
          end
        end
      end
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

    def delete(key)
      return unless declaration_data.key?(key)

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
    end

    def class?
      declaration_data.is_a?(::Class)
    end

    def []=(key, value)
      if strict?
        self.is_strict = false
      end

      unless duped?
        self.declaration_data = declaration_data.dup
        self.is_duped = true
      end

      declaration_data[key] = value
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

      declaration
    end

    def slice(...)
      parts = declaration_data.slice(...)

      declaration = clone_from_part(parts)
      declaration.is_duped = true

      if declaration.strict?
        declaration.is_strict = false
      end

      declaration
    end

    def assign(other)
      self.declaration_data = other.declaration_data

      if absolutified? != other.absolutified?
        self.is_absolutified = other.absolutified?
      end

      if strict? != other.strict?
        self.is_strict = other.strict?
      end

      if duped? != other.duped?
        self.is_duped = other.duped?
      end

      if deep_duped? != other.deep_duped?
        self.is_deep_duped = other.deep_duped?
      end

      if other.type
        self.type = other.type
      end

      if other.base_type
        self.base_type = other.base_type
      end
    end

    def clone
      declaration = TypeDeclaration.new(declaration_data, false, true)

      if strict?
        declaration.is_strict = true
      end

      if absolutified?
        declaration.is_absolutified = true
      end

      if type
        declaration.type = type
      end

      if base_type
        declaration.base_type = base_type
      end

      if reference_checked?
        declaration.reference_checked = true
      end

      declaration
    end

    def clone_from_part(part)
      TypeDeclaration.new(part)
    end

    def reference?
      strict? && declaration_data.is_a?(::Symbol)
    end

    alias absolutified? is_absolutified
    alias duped? is_duped
    alias deep_duped? is_deep_duped
    alias strict? is_strict
    alias reference_checked? reference_checked
  end
end
