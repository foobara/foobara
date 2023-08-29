require "foobara/command/runtime_command_error"

module Foobara
  class Command
    module Concerns
      module Subcommands
        extend ActiveSupport::Concern

        class AlreadyRegisteredSubcommand < StandardError; end
        class SubcommandNotRegistered < StandardError; end

        class FailedToExecuteSubcommand < Foobara::Command::RuntimeCommandError
          attr_accessor :causes

          def initialize(causes:, **args)
            super(**args)

            self.causes = causes
          end
        end

        attr_accessor :is_subcommand

        delegate :verify_depends_on!, to: :class

        def subcommand?
          is_subcommand
        end

        def run_subcommand!(subcommand_class, inputs = {})
          verify_depends_on!(subcommand_class)

          subcommand = subcommand_class.new(inputs)
          subcommand.is_subcommand = true
          outcome = subcommand.run

          if outcome.success?
            outcome.result
          else
            add_runtime_error(
              symbol: self.class.could_not_run_subcommand_symbol_for(subcommand_class),
              message: "Failed to execute #{subcommand_class.name}",
              # TODO: how to translate this hash into a context_type_declaration???
              # Oh... we can just use the error_context_type_map as a type declaration?? Does that actually work?
              context: subcommand.error_hash,
              causes: outcome.errors
            )
          end
        end

        class_methods do
          def depends_on?(subcommand_name)
            subcommand_name = if subcommand_name.is_a?(Class)
                                subcommand_name.name
                              end

            depends_on.include?(subcommand_name.to_sym)
          end

          def depends_on(*subcommand_classes)
            return @depends_on ||= Set.new if subcommand_classes.empty?

            if subcommand_classes.length == 1
              subcommand_classes = Array.wrap(subcommand_classes.first)
            end

            subcommand_classes.each do |subcommand_class|
              subcommand_name = subcommand_class.name.to_sym

              if depends_on.include?(subcommand_name)
                # :nocov:
                raise AlreadyRegisteredSubcommand, "Already registered #{subcommand_class} as a dependency of #{self}"
                # :nocov:
              end

              depends_on << subcommand_name

              error_class = to_could_not_run_subcommand_error_class(subcommand_class)
              possible_could_not_run_subcommand_error(error_class)
            end
          end

          def verify_depends_on!(subcommand_class)
            unless depends_on?(subcommand_class)
              # :nocov:
              raise SubcommandNotRegistered, "Need to declare #{subcommand_class} on #{self} with .depends_on"
              # :nocov:
            end
          end
        end
      end
    end
  end
end
