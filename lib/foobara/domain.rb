Foobara::Util.require_directory("#{__dir__}/domain")

module Foobara
  class Domain
    class AlreadyRegisteredDomainDependency < StandardError; end
    class DomainDependencyNotRegistered < StandardError; end

    attr_accessor :superdomain

    def initialize(superdomain = nil)
      self.superdomain = superdomain
      Domain.all << self
      @command_classes = []
    end

    delegate :name, to: :class

    def type_namespace
      @type_namespace ||= if superdomain
                            Foobara::TypeDeclarations::Namespace.new(name, accesses: superdomain)
                          else
                            Foobara::TypeDeclarations::Namespace.new(name)
                          end
    end

    def command_classes
      Domain.process_command_classes
      @command_classes
    end

    def owns_command_class?(command_class)
      command_classes.include?(command_class)
    end

    def register_commands(command_classes)
      command_classes.each do |command_class|
        register_command(command_class)
      end
    end

    def register_command(command_class)
      @command_classes << command_class
    end

    def depends_on?(domain)
      domain = domain.name if domain.is_a?(Class) || domain.is_a?(Domain)

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

    def verify_depends_on!(domain_class)
      unless depends_on?(domain_class)
        # :nocov:
        raise DomainDependencyNotRegistered, "Need to declare #{domain_class} on #{self} with .depends_on"
        # :nocov:
      end
    end

    class << self
      def all
        @all ||= []
      end

      def unprocessed_command_classes
        @unprocessed_command_classes ||= []
      end

      def process_command_classes
        until unprocessed_command_classes.empty?
          command_class = unprocessed_command_classes.pop

          command_class = const_get(command_class) unless command_class.is_a?(Class)
          domain = autodetect_domain(command_class)

          domain&.register_command(command_class)
        end
      end

      def autodetect_domain(command_class)
        namespace = Foobara::Util.module_for(command_class)

        if namespace&.ancestors&.include?(Foobara::Domain)
          namespace
        end
      end

      def reset_unprocessed_command_classes
        @unprocessed_command_classes = nil
      end

      def reset_all
        @all = nil
      end

      def install!
        return if @installed

        @installed = true
        Foobara::Command.include(Foobara::Domain::CommandExtension)
        Foobara::Command.after_subclass_defined do |subclass|
          unprocessed_command_classes << subclass
        end
      end

      def instance
        @instance ||= new
      end

      delegate :depends_on, :depends_on?, :register_command, :register_commands, to: :instance
    end
  end
end

Foobara::Domain.install!
