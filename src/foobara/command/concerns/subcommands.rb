module Foobara
  class Command
    module Concerns
      module Subcommands
        extend ActiveSupport::Concern

        class AlreadyRegisteredSubcommand < StandardError; end
        class SubcommandNotRegistered < StandardError; end

        attr_accessor :is_subcommand

        def sub_command?
          is_subcommand
        end

        def run_subcommand!(subcommand_class, inputs)
          unless self.class.depends_on?(subcommand_class)
            raise SubcommandNotRegistered, "Need to declare #{subcommand_class} on #{self.class} with .depends_on"
          end

          subcommand = subcommand_class.new(inputs)
          subcommand.is_subcommand = true
          outcome = subcommand.run

          if outcome.success?
            outcome.result
          else
            add_runtime_error(
              symbol: self.class.possible_error_symbol_for(subcommand_class),
              message: "Failed to execute #{subcommand_class.name}",
              context: subcommand.error_hash
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
                raise AlreadyRegisteredSubcommand, "Already registered #{subcommand_class} as a dependency of #{self}"
              end

              depends_on << subcommand_name

              possible_error(
                possible_error_symbol_for(subcommand_class),
                subcommand_class.error_context_schema_map
              )
            end
          end

          def possible_error_symbol_for(command_class)
            "could_not_#{command_class.name.demodulize.underscore}".to_sym
          end
        end
      end
    end
  end
end