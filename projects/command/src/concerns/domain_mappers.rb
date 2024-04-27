module Foobara
  class Command
    module Concerns
      module DomainMappers
        include Concern

        def run_mapped_subcommand!(subcommand_class, unmapped_inputs)
          inputs = domain_map!(unmapped_inputs, to: subcommand_class, strict: true)

          result = run_subcommand!(subcommand_class, inputs)

          result_mapper = self.class.domain.foobara_domain_mapper_registry.lookup(
            from: result,
            to: result_type,
            strict: true
          )

          if result_mapper
            result_mapper.map(result)
          else
            result
          end
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
