module Foobara
  class Command
    module Concerns
      module DomainMappers
        include Concern

        def run_mapped_subcommand!(subcommand_class, *args)
          unmapped_inputs, has_result_type, result_type =
            case args.size
            when 0
              [{}]
            when 1
              [args.first]
            when 2
              [args[1], true, args[0]]
            else
              raise ArgumentError,
                    "wrong number of arguments (#{args.size}. Expected inputs, result_type and inputs, or nothing."
            end

          inputs = domain_map!(unmapped_inputs, to: subcommand_class, strict: true)

          result = run_subcommand!(subcommand_class, inputs)

          if has_result_type
            result_mapper = self.class.domain.foobara_domain_mapper_registry.lookup!(
              from: result,
              to: result_type,
              strict: true
            )

            result = result_mapper.map(result)
          end

          result
        end

        def domain_map(...)
          self.class.domain.foobara_domain_map(...)
        end

        def domain_map!(...)
          self.class.domain.foobara_domain_map!(...)
        end
      end
    end
  end
end
