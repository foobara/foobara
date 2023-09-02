module Foobara
  class Command
    module Concerns
      module Subcommands
        extend ActiveSupport::Concern

        class AlreadyRegisteredSubcommand < StandardError; end
        class SubcommandNotRegistered < StandardError; end

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
                raise AlreadyRegisteredSubcommand,
                      "Already registered #{subcommand_class} as a dependency of #{self}"
                # :nocov:
              end

              depends_on << subcommand_name

              register_possible_subcommand_errors(subcommand_class)
            end
          end

          def verify_depends_on!(subcommand_class)
            unless depends_on?(subcommand_class)
              # :nocov:
              raise SubcommandNotRegistered, "Need to declare #{subcommand_class} on #{self} with .depends_on"
              # :nocov:
            end
          end

          private

          def register_possible_subcommand_errors(subcommand_class)
            subcommand_class.error_context_type_map.each_pair do |key, error_class|
              error_key = ErrorKey.prepend_runtime_path(key, subcommand_class.runtime_path_symbol)
              register_possible_error_class(error_key, error_class)
            end
          end
        end
      end
    end
  end
end
