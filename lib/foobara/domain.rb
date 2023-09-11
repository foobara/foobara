Foobara::Util.require_directory("#{__dir__}/domain")

module Foobara
  class Domain
    class AlreadyRegisteredDomainDependency < StandardError; end

    attr_accessor :organization, :domain_name, :model_classes

    def initialize(domain_name:, organization: nil)
      self.domain_name = domain_name
      self.organization = organization
      Domain.all << self
      @command_classes = []
      @model_classes = []
    end

    delegate :organization_name, :organization_symbol, to: :organization, allow_nil: true

    def type_namespace
      @type_namespace ||= Foobara::TypeDeclarations::Namespace.new(full_domain_name)
    end

    def full_domain_name
      if organization.present?
        "#{organization_name}::#{domain_name}"
      else
        domain_name
      end
    end

    def domain_symbol
      @domain_symbol ||= domain_name.underscore.to_sym
    end

    def full_domain_symbol
      @full_domain_symbol ||= if organization.present?
                                "#{organization_symbol}::#{domain_symbol}".to_sym
                              else
                                domain_symbol
                              end.to_sym
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
      type_namespace.register_type(model_class.model_name, model_class.model_type)
    end

    def depends_on?(domain)
      if domain.is_a?(Domain)
        domain = domain.domain_name
      end

      depends_on.include?(domain.to_sym)
    end

    def depends_on(*domain_classes)
      return @depends_on ||= Set.new if domain_classes.empty?

      if domain_classes.length == 1
        domain_classes = Array.wrap(domain_classes.first)
      end

      domain_classes.each do |domain_class|
        domain_name = domain_class.name.to_sym

        if depends_on.include?(domain_name)
          # :nocov:
          raise AlreadyRegisteredDomainDependency, "Already registered #{domain_class} as a dependency of #{self}"
          # :nocov:
        end

        depends_on << domain_name
      end
    end

    # commands... types... models... errors?
    def manifest
      {
        organization_name:,
        domain_name:,
        full_domain_name:,
        depends_on: depends_on.map(&:full_domain_name),
        commands: command_classes.map(&:command_name),
        models: model_classes.map(&:model_name),
        types: type_namespace.manifest
      }
    end

    class << self
      def all
        @all ||= []
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

      def reset_all
        %w[
          all
          global
          foobara_organization_modules
          foobara_domain_modules
          unprocessed_command_classes
        ].each do |var_name|
          var_name = "@#{var_name}"
          remove_instance_variable(var_name) if instance_variable_defined?(var_name)
        end
      end

      def install!
        if @installed
          # :nocov:
          raise "Already registered Domain"
          # :nocov:
        end

        @installed = true
        Module.include(Foobara::Domain::ModuleExtension)
        Foobara::Command.include(Foobara::Domain::CommandExtension)
        Foobara::Command.after_subclass_defined do |subclass|
          unprocessed_command_classes << subclass
        end
      end
    end
  end
end

Foobara::Domain.install!
