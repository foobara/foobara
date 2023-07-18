module Foobara
  class Domain
    class AlreadyRegisteredDomainDependency < StandardError; end
    class DomainDependencyNotRegistered < StandardError; end

    attr_accessor :command_classes

    def initialize
      self.command_classes = []

      Foobara::Command.after_subclass_defined do |subclass|
        if subclass.domain == self
          command_classes << subclass
        end
      end

      # TODO: this is pretty nasty... figure out the proper place for this load order to be resolved
      Foobara::Command.include(Foobara::Domain::CommandExtension)
    end

    class << self
      def instance
        @instance ||= new
      end

      def depends_on?(domain_name)
        domain_name = if domain_name.is_a?(Class)
                        domain_name.name
                      end

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
    end
  end
end
