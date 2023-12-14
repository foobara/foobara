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

      def domain_name
        domain.domain_name
      end

      def organization_name
        organization.organization_name
      end

      def domain
        manifest = self

        domain_reference = nil

        until domain_reference || manifest.nil?
          domain_reference = manifest[:domain]

          unless domain_reference
            parent = manifest.parent

            manifest = if parent
                         BaseManifest.new(root_manifest, parent)
                       end
          end
        end

        if domain_reference
          Domain.new(root_manifest, [:domain, domain_reference])
        else
          global_domain
        end
      end

      def organization
        manifest = relevant_manifest

        org_reference = nil

        until org_reference || manifest.nil?
          org_reference = DataPath.value_at(:organization, manifest)

          unless org_reference
            parent = manifest["parent"]

            manifest = if parent
                         manifest = BaseManifest.new(root_manifest, parent).relevant_manifest
                       end
          end
        end

        if org_reference
          Organization.new(root_manifest, [:organization, org_reference])
        else
          global_organization
        end
      end

      def parent
        relevant_manifest[:parent]
      end

      def parent_category
        parent&.first
      end

      def parent_name
        parent&.last
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
          nil
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
