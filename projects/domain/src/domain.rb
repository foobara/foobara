module Foobara
  class Domain
    class AlreadyRegisteredDomainDependency < StandardError; end
    class NoSuchDomain < StandardError; end

    attr_accessor :organization, :domain_name, :model_classes, :is_global, :mod

    def initialize(mod:, domain_name: nil, organization: Organization.global, global: false)
      self.mod = mod
      self.is_global = global

      if global?
        @type_namespace = TypeDeclarations::Namespace.global
      else
        if domain_name.nil? || domain_name.empty?
          # :nocov:
          raise ArgumentError, "Must provide an domain_name:"
          # :nocov:
        end

        self.domain_name = domain_name
      end

      self.organization = organization
      organization.register_domain(self)
      # TODO: explode if same name used twice
      Domain.all[all_key] = self
      @command_classes = []
      @model_classes = []
    end

    foobara_delegate :organization_name, :organization_symbol, to: :organization, allow_nil: true
    foobara_delegate :type_for_declaration, to: :type_namespace

    def global?
      is_global
    end

    def all_key
      if global?
        nil
      else
        full_domain_name.to_sym
      end
    end

    def type_namespace
      @type_namespace ||= TypeDeclarations::Namespace.new(full_domain_name)
    end

    def type_registered?(type_or_symbol)
      type_namespace.type_registered?(type_or_symbol)
    end

    def full_domain_name
      names = [
        organization_name,
        domain_name
      ].compact

      if names.empty?
        nil
      else
        names.join("::")
      end
    end

    def domain_symbol
      @domain_symbol ||= unless global?
                           Util.underscore_sym(domain_name)
                         end
    end

    def full_domain_symbol
      return @full_domain_symbol if defined?(@full_domain_symbol)

      names = [
        organization_symbol,
        domain_symbol
      ].compact

      @full_domain_symbol = names.empty? ? nil : names.join("::").to_sym
    end

    def command_classes
      Domain.process_command_classes
      @command_classes
    end

    def register_command(command_class)
      @command_classes << command_class
    end

    def register_model(model_class)
      @model_classes << model_class
      type_namespace.register_type(model_class.model_symbol, model_class.model_type)
    end

    def depends_on?(other_domain)
      return true if global?

      other_domain = self.class.to_domain(other_domain)

      other_domain.global? || other_domain == self || depends_on.include?(other_domain.all_key)
    end

    def depends_on(*domains)
      return @depends_on ||= Set.new if domains.empty?

      if domains.length == 1
        domains = Util.array(domains.first)
      end

      domains.each do |domain|
        # It very likely could be a module extended with domain methods...
        domain = self.class.to_domain(domain)
        domain_name = domain.all_key

        if depends_on.include?(domain_name)
          # :nocov:
          raise AlreadyRegisteredDomainDependency, "Already registered #{domain_name} as a dependency of #{self}"
          # :nocov:
        end

        depends_on << domain_name
      end
    end

    def manifest
      Util.remove_empty(
        depends_on: depends_on.map(&:to_s),
        commands: command_classes.map(&:manifest_hash).inject(:merge) || {},
        types: type_namespace.manifest
      )
    end

    def manifest_hash
      key = domain_name || "global_domain"

      {
        key.to_sym => manifest
      }
    end

    class << self
      def to_domain(object)
        case object
        when nil
          global
        when ::String, ::Symbol
          Domain.all[object.to_sym]
        when Domain
          object
        when Types::Type
          namespace = TypeDeclarations::Namespace.namespace_for_type(object)
          domain_for_namespace(namespace)
        when Module
          if object < DomainModuleExtension
            object.foobara_domain
          else
            # :nocov:
            raise NoSuchDomain, "Couldn't determine domain for #{object}"
            # :nocov:
          end
        else
          # :nocov:
          raise NoSuchDomain, "Couldn't determine domain for #{object}"
          # :nocov:
        end
      end

      def domain_for_namespace(namespace)
        all.values.find { |domain| domain.type_namespace == namespace }
      end

      def global
        return @global if defined?(@global)

        @global = new(global: true, organization: Organization.global, mod: nil)
      end

      def all
        @all ||= {}
      end

      def foobara_organization_modules
        @foobara_organization_modules ||= []
      end

      def foobara_domain_modules
        @foobara_domain_modules ||= []
      end

      def unprocessed_command_classes
        @unprocessed_command_classes ||= []
      end

      def process_command_classes
        until unprocessed_command_classes.empty?
          command_class = unprocessed_command_classes.pop
          domain = command_class.domain

          domain&.register_command(command_class)
        end
      end

      def create(full_name)
        domain_name, organization_name = full_name.to_s.split("::").reverse

        if organization_name
          org = Organization[organization_name] || Organization.create(organization_name)
        end

        mod = Module.new

        org&.mod&.const_set(domain_name, mod)

        mod.foobara_domain!
        mod.foobara_domain
      end
    end
  end
end
