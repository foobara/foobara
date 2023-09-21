module Foobara
  module Common
    # TODO: figure out how to share code between here and ErrorKey
    # TODO: use this to implement computed attributes
    class DataPath
      # TODO: use this wherever it makes sense
      EMPTY_PATH = [].freeze

      class << self
        def to_s_type(key)
          unless key.is_a?(DataPath)
            key = parse(key)
          end

          key.to_s_type
        end

        def values_at(data_path, object)
          unless data_path.is_a?(DataPath)
            data_path = parse(data_path)
          end

          data_path.values_at(object)
        end

        def prepend_path(key, *)
          if key.is_a?(DataPath)
            key.prepend(*)
          else
            key = parse(key)
            key.prepend!(*).to_s
          end
        end

        def append_path(key, *)
          if key.is_a?(DataPath)
            key.append(*)
          else
            key = parse(key)
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

      def values_at(objects, parts = path)
        objects = Array.wrap(objects)

        return objects if parts.empty?

        path_part, *parts = parts

        objects = case path_part
                  when :"#"
                    objects.flatten
                  when Symbol
                    objects.map do |object|
                      if object.is_a?(::Hash)
                        object[path_part]
                      else
                        object.send(path_part)
                      end
                    end
                  when Integer
                    objects.map { |value| value[path_part] }
                  else
                    # :nocov:
                    raise "Bad path part #{path_part}"
                    # :nocov:
                  end

        values_at(objects, parts)
      end

      def ==(other)
        self.class == other.class && path == other.path
      end

      private

      def normalize_all(key_parts)
        normalize(Array.wrap(key_parts))
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
          if key_parts.blank?
            nil
          elsif key_parts =~ INDEX_VALUE
            key_parts.to_i
          else
            key_parts.to_sym
          end
        else
          # :nocov:
          raise ArgumentError, "expected nil, a symbol, or a string, an integer, or an array of such values "
          # :nocov:
        end
      end
    end
  end
end