module Foobara
  module CommandPatternImplementation
    module Concerns
      module Subcommands
        include Concern

        class AlreadyRegisteredSubcommand < StandardError; end
        class SubcommandNotRegistered < StandardError; end
        class CannotAccessDomain < StandardError; end

        attr_accessor :is_subcommand

        foobara_delegate :verify_depends_on!, to: :class

        def subcommand?
          is_subcommand
        end

        def run_subcommand!(subcommand_class, inputs = {})
          domain = self.class.domain
          sub_domain = subcommand_class.domain

          unless domain.foobara_can_call_subcommands_from?(sub_domain)
            raise CannotAccessDomain,
                  "Cannot access #{sub_domain} or its commands because #{domain} does not depend on it"
          end

          verify_depends_on!(subcommand_class)

          subcommand = subcommand_class.new(inputs)
          subcommand.is_subcommand = true
          outcome = subcommand.run

          if outcome.success?
            outcome.result
          else
            outcome.errors.each do |error|
              # problem... inner command could have a different category but we want this to be a runtime error...
              # So I guess we should use our error class anyways but override its methods...
              # Or do we want to let the inner category reign? Issue with that is the subcommand could have the same
              # name as an input and collide (unlikely but possible.)
              # So what to do? Wrapper error? Maybe introduce a sub command category for the wrapper?
              # other solution instead.... add a runtime_path to Error
              add_subcommand_error(subcommand, error)
            end
          end
        end

        module ClassMethods
          def depends_on?(subcommand_name)
            if subcommand_name.is_a?(Class)
              subcommand_name = subcommand_name.scoped_full_name.to_sym
            end

            depends_on.include?(subcommand_name.to_sym)
          end

          def depends_on(*subcommand_classes)
            if subcommand_classes.empty?
              return @depends_on if defined?(@depends_on)

              # TODO: get Command and DomainMapper out of here!
              @depends_on = if self == Foobara::Command || self == Foobara::DomainMapper
                              Set.new
                            else
                              superclass.depends_on.dup
                            end

              return @depends_on
            end

            if subcommand_classes.length == 1
              subcommand_classes = Util.array(subcommand_classes.first)
            end

            subcommand_classes.each do |subcommand_class|
              subcommand_name = subcommand_class.scoped_full_name.to_sym

              if depends_on.include?(subcommand_name)
                # :nocov:
                raise AlreadyRegisteredSubcommand,
                      "Already registered #{subcommand_class} as a dependency of #{self}"
                # :nocov:
              end

              depends_on << subcommand_name

              register_possible_subcommand_errors(subcommand_class)
            end
          end

          def verify_depends_on!(subcommand_class)
            unless domain_map_criteria
              return if subcommand_class < DomainMapper
            end

            unless depends_on?(subcommand_class)
              # :nocov:
              raise SubcommandNotRegistered, "Need to declare #{subcommand_class} on #{self} with .depends_on"
              # :nocov:
            end
          end

          private

          def register_possible_subcommand_errors(subcommand_class)
            subcommand_class.possible_errors.each do |possible_error|
              possible_error = possible_error.dup
              possible_error.prepend_runtime_path!(subcommand_class.full_command_symbol)
              register_possible_error_class(possible_error)
            end
          end
        end
      end
    end
  end
end
