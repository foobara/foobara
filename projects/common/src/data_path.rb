module Foobara
  # TODO: figure out how to share code between here and ErrorKey
  # TODO: use this to implement computed attributes
  class DataPath
    class BadPathError < StandardError; end

    # TODO: use this wherever it makes sense
    EMPTY_PATH = [].freeze

    class TooManyValuesAtPathError < StandardError
      attr_accessor :path, :values

      def initialize(path, values)
        self.path = path
        self.values = values

        super(message)
      end

      def message
        "Expected only one value to be at #{path} but there were #{values.size}: #{values}"
      end
    end

    class << self
      def to_s_type(key)
        unless key.is_a?(DataPath)
          key = new(key)
        end

        key.to_s_type
      end

      def values_at(data_path, object)
        unless data_path.is_a?(DataPath)
          data_path = new(data_path)
        end

        data_path.values_at(object)
      end

      def value_at(data_path, object)
        unless data_path.is_a?(DataPath)
          data_path = new(data_path)
        end

        data_path.value_at(object)
      end

      def set_value_at(object, value, data_path)
        unless data_path.is_a?(DataPath)
          data_path = new(data_path)
        end

        data_path.set_value_at(object, value)
      end

      def prepend_path(key, *)
        if key.is_a?(DataPath)
          key.prepend(*)
        else
          key = new(key)
          key.prepend!(*).to_s
        end
      end

      def append_path(key, *)
        if key.is_a?(DataPath)
          key.append(*)
        else
          key = new(key)
          key.append!(*).to_s
        end
      end

      def parse(key_string)
        new(key_string)
      end
    end

    attr_reader :path

    # TODO: accept error_class instead of symbol/category??
    def initialize(path = [])
      path = path.to_s if path.is_a?(::Symbol)
      path = path.split(".") if path.is_a?(::String)

      self.path = path
    end

    def path=(path)
      @path = normalize_all(path)
    end

    def prepend!(*prepend_parts)
      if prepend_parts.size == 1
        arg = prepend_parts.first

        if arg.is_a?(Array)
          prepend_parts = arg
        end
      end

      self.path = [*prepend_parts, *path]
      self
    end

    def prepend(*)
      dup.tap do |key|
        key.prepend!(*)
      end
    end

    def append!(*append_parts)
      if append_parts.size == 1
        arg = append_parts.first

        if arg.is_a?(Array)
          append_parts = arg
        end
      end

      self.path = [*path, *append_parts]
      self
    end

    def append(*)
      dup.tap do |key|
        key.append!(*)
      end
    end

    INDEX_VALUE = /\A\d+\z/

    def to_type!
      path.map! do |part|
        part.is_a?(Integer) ? :"#" : part
      end
    end

    def to_type
      dup.tap(&:to_type!)
    end

    def to_s
      path.join(".")
    end

    def to_sym(...)
      to_s(...).to_sym
    end

    def to_s_type
      to_type.to_s
    end

    def values_at(object, parts = path)
      _values_at([object], parts)
    end

    def value_at(object, parts = path)
      values = values_at(object, parts)

      if values.size > 1
        raise TooManyValuesAtPathError.new(path, values)
      end

      values.first
    end

    def set_value_at(object, value, parts = path)
      owner = value_at(object, parts[0..-2])
      index = parts.last

      if owner.is_a?(::Hash)
        if owner.key?(index.to_s)
          owner[index.to_s] = value
        else
          owner[index] = value
        end
      elsif owner.is_a?(::Array)
        owner[index] = value
      else
        method = "#{index}="
        if owner.respond_to?(method)
          owner.send(method, value)
        else
          # :nocov:
          raise BadPathError, "Bad path: #{parts}"
          # :nocov:
        end
      end

      value
    end

    # Helper method that determines if the path points to an array and none of the atoms along the way are also arrays.
    # And that there's at least one atom (we are going to consider a collection to be "named" not an anonymous array.)
    def simple_collection?
      path.size > 1 && path.last == :"#" && path[0..-2].none? { |part| part == :"#" }
    end

    def ==(other)
      self.class == other.class && path == other.path
    end

    private

    def normalize_all(key_parts)
      normalize(Util.array(key_parts))
    end

    def normalize(key_parts)
      return nil if key_parts.nil?

      case key_parts
      when Array
        key_parts.map do |key_part|
          normalize(key_part)
        end
      when Symbol
        normalize(key_parts.to_s)
      when Integer
        key_parts
      when String
        if key_parts.empty?
          nil
        elsif key_parts =~ INDEX_VALUE
          key_parts.to_i
        else
          key_parts.to_sym
        end
      else
        # :nocov:
        raise ArgumentError,
              "expected nil, a symbol, or a string, an integer, or an array of such values but was a #{key_parts.class}"
        # :nocov:
      end
    end

    def _values_at(objects, parts = path)
      return objects if parts.empty?

      path_part, *parts = parts

      objects = case path_part
                when :"#"
                  objects.flatten.uniq
                when Symbol
                  objects.map do |object|
                    if object.is_a?(::Hash)
                      if object.key?(path_part.to_s)
                        object[path_part.to_s]
                      else
                        object[path_part]
                      end
                    else
                      object.send(path_part)
                    end
                  end
                when Integer
                  objects.map { |value| value[path_part] }
                else
                  # :nocov:
                  raise "Bad path part: #{path_part.inspect}"
                  # :nocov:
                end.compact

      _values_at(objects, parts)
    end
  end
end
