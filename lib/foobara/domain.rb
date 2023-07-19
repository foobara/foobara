module Foobara
  class Domain
    class AlreadyRegisteredDomainDependency < StandardError; end
    class DomainDependencyNotRegistered < StandardError; end

    attr_accessor :command_classes

    def initialize
      self.command_classes = []
    end

    def register_commands(command_classes)
      command_classes.each do |command_class|
        register_command(command_class)
      end
    end

    def register_command(command_class)
      @command_classes << command_class
    end

    def depends_on?(domain_name)
      domain_name = domain_name.name if domain_name.is_a?(Class)
      domain_name = domain_name.to_sym

      depends_on.include?(domain_name.to_sym)
    end

    def depends_on(*domain_classes)
      return @depends_on ||= Set.new if domain_classes.empty?

      if domain_classes.length == 1
        domain_classes = Array.wrap(domain_classes.first)
      end

      domain_classes.each do |domain_class|
        domain_name = domain_class.name.to_sym

        if depends_on.include?(domain_name)
          raise AlreadyRegisteredDomainDependency, "Already registered #{domain_class} as a dependency of #{self}"
        end

        depends_on << domain_name
      end
    end

    def verify_depends_on!(domain_class)
      unless depends_on?(domain_class)
        raise DomainDependencyNotRegistered, "Need to declare #{domain_class} on #{self} with .depends_on"
      end
    end

    class << self
      def install!
        Foobara::Command.include(Foobara::Domain::CommandExtension)
      end

      def instance
        @instance ||= new
      end

      delegate :depends_on, :depends_on?, :register_command, :register_commands, to: :instance
    end
  end
end
