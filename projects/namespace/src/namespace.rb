require_relative "scoped"

module Foobara
  class Namespace
    include Scoped

    attr_accessor :accesses

    def initialize(scoped_name_or_path, acceses: [], namespace: nil)
      self.namespace = namespace
      self.accesses = accesses

      self.scoped_path = if scoped_name_or_path.is_a?(String)
                           scoped_name_or_path.split("::")
                         else
                           scoped_name_or_path
                         end
    end

    def register(scoped)
      if scoped_name_to_scoped.key?(scoped.scoped_name)
        raise "#{scoped.scoped_name} is already registered"
      end

      if scoped.namespace && namespace != self
        raise "#{scoped.scoped_name} is already registered in #{scoped.namespace}"
      end

      short_name_to_scoped[scoped.scoped_short_name] ||= []
      short_name_to_scoped[scoped.scoped_short_name] |= [scoped]

      scoped_name_to_scoped[scoped.scoped_name] = scoped
    end

    def lookup(name)
      if name.is_a?(Array)
        name = name.join("::")
      end

      object = scoped_name_to_scoped[name]
      return object if object

      object = short_name_to_scoped[name]

      if object
        if object.size > 1
          raise "#{name} is ambiguous. Could be any of: #{object.map(&:scoped_name).join(", ")}"
        end

        object.first
      end
    end

    def lookup!(name)
      object = lookup(name)

      unless object
        raise "Could not find #{name}"
      end

      object
    end

    def scoped_name_to_scoped
      @scoped_name_to_scoped ||= {}
    end

    def short_name_to_scoped
      @short_name_to_scoped ||= {}
    end
  end
end
