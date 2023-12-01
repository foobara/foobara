module Foobara
  module Manifest
    class BaseManifest
      include TruncatedInspect

      attr_accessor :root_manifest, :path

      class << self
        def optional_keys(*values)
          if values.empty?
            @optional_keys ||= Set.new
          else
            values.each do |value|
              optional_keys << value.to_sym
            end
          end
        end

        def optional_key(value)
          optional_keys(value)
        end
      end

      def initialize(root_manifest, path)
        self.root_manifest = root_manifest
        self.path = path

        if relevant_manifest.nil?
          # :nocov:
          raise "invalid path #{path}"
          # :nocov:
        end
      end

      def relevant_manifest
        @relevant_manifest ||= Foobara::DataPath.values_at(path, root_manifest).first
      end

      def global_organization?
        organization_name == "global_organization"
      end

      def global_domain?
        domain_name == "global_domain"
      end

      def find_type(type_declaration, domain = nil)
        type_symbol = type_declaration.type

        if domain.nil?
          path = type_declaration.path[0..3]
          domain = Domain.new(root_manifest, path)

          type = find_type(type_declaration, domain)
          type ||= find_type(type_declaration, global_domain)

          unless type
            # :nocov:
            raise "Could not find a type for #{type_symbol}"
            # :nocov:
          end

          type
        else
          type = domain.types.find { |t| t.name.to_sym == type_symbol.to_sym }

          return type if type

          domain.depends_on.each do |domain_name|
            dependent_domain = domain_name_to_domain(domain_name)
            type = find_type(type_declaration, dependent_domain)

            return type if type
          end

          nil
        end
      end

      def domain_name_to_domain(full_domain_name)
        *organization_name, domain_name = full_domain_name.split("::")
        organization_name = organization_name.first || "global_organization"

        Domain.new(root_manifest, [:organizations, organization_name, :domains, domain_name])
      end

      def global_domain
        Domain.new(root_manifest, [:organizations, "global_organization", :domains, "global_domain"])
      end

      def method_missing(method_name, *, &)
        if relevant_manifest.key?(method_name.to_sym)
          relevant_manifest[method_name.to_sym]
        elsif relevant_manifest.key?(method_name.to_s)
          relevant_manifest[method_name.to_s]
        elsif optional_key?(method_name)
          nil
        else
          # :nocov:
          super
          # :nocov:
        end
      end

      def optional_key?(key)
        if key.is_a?(::Symbol) || key.is_a?(::String)
          self.class.optional_keys.include?(key.to_sym)
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        relevant_manifest.key?(method_name.to_sym) || relevant_manifest.key?(method_name.to_s) || super
      end

      def ==(other)
        other.class == self.class && other.root_manifest == root_manifest &&
          other.path.map(&:to_sym) == path.map(&:to_sym)
      end

      def eql?(other)
        self == other
      end

      def hash
        [root_manifest, path.map(&:to_sym)].hash
      end
    end
  end
end
