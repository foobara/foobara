module Foobara
  module Manifest
    class BaseManifest
      include TruncatedInspect

      attr_accessor :root_manifest, :path

      class << self
        attr_accessor :category_symbol

        def optional_keys(*values, default: nil)
          if values.empty?
            @optional_keys ||= Set.new
          else
            if default
              default = default.freeze
            end

            values.each do |value|
              value = value.to_sym
              optional_keys << value
              if default
                optional_key_defaults[value] = default
              end
            end
          end
        end

        def optional_key_defaults
          @optional_key_defaults ||= {}
        end

        def optional_key(value, default: nil)
          optional_keys(value, default:)
        end

        def category_to_manifest_class(category_symbol)
          category_symbol = category_symbol.to_sym

          Util.descendants(BaseManifest).find do |manifest_class|
            manifest_class.category_symbol == category_symbol
          end
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

      def domain_name
        domain.domain_name
      end

      def organization_name
        organization.organization_name
      end

      def domain
        domain_reference = self[:domain]

        if domain_reference
          Domain.new(root_manifest, [:domain, domain_reference])
        else
          global_domain
        end
      end

      def organization
        organization_reference = self[:organization]

        if organization_reference
          Organization.new(root_manifest, [:organization, organization_reference])
        else
          global_organization
        end
      end

      def parent
        if parent_category
          parent_class = self.class.category_to_manifest_class(parent_category)

          parent_class&.new(root_manifest, self[:parent])
        end
      end

      def parent_category
        self[:parent]&.first
      end

      def parent_name
        self[:parent]&.last
      end

      def scoped_category
        self[:scoped_category]
      end

      def relevant_manifest
        @relevant_manifest ||= Foobara::DataPath.values_at(path, root_manifest).first
      end

      def find_type(type_declaration)
        type_symbol = type_declaration.type

        Type.new(root_manifest, [:type, type_symbol])
      end

      def domain_name_to_domain(full_domain_name)
        Domain.new(root_manifest, [:domain, full_domain_name])
      end

      def global_domain
        Domain.new(root_manifest, %i[domain global_organization::global_domain])
      end

      def global_organization
        Organization.new(root_manifest, %i[organization global_organization])
      end

      def method_missing(method_name, *, &)
        if key?(method_name)
          self[method_name]
        elsif optional_key?(method_name)
          self.class.optional_key_defaults[method_name.to_sym]
        else
          # :nocov:
          super
          # :nocov:
        end
      end

      def [](method_name)
        if relevant_manifest.key?(method_name.to_sym)
          relevant_manifest[method_name.to_sym]
        elsif relevant_manifest.key?(method_name.to_s)
          relevant_manifest[method_name.to_s]
        end
      end

      def key?(method_name)
        relevant_manifest.key?(method_name.to_sym) || relevant_manifest.key?(method_name.to_s)
      end

      def optional_key?(key)
        if key.is_a?(::Symbol) || key.is_a?(::String)
          self.class.optional_keys.include?(key.to_sym)
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        relevant_manifest.key?(method_name.to_sym) || relevant_manifest.key?(method_name.to_s) ||
          optional_key?(method_name) || super
      end

      def ==(other)
        other.class == self.class && other.path.map(&:to_sym) == path.map(&:to_sym)
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
