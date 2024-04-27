module Foobara
  class Command
    module Concerns
      module DomainMappers
        include Concern

        def run_mapped_subcommand!(subcommand_class, unmapped_inputs)
          inputs = domain_map!(unmapped_inputs, to_type: subcommand_class)

          result = run_subcommand!(subcommand_class, inputs)

          result_mapper = self.class.domain.foobara_domain_mapper_registry.lookup(
            from_type: result.class,
            to_type: self.class
          )

          if result_mapper
            result_mapper.call(result)
          else
            result
          end
        end

        def domain_map!(from_value, from_type: nil, to_type: nil)
          mapper_class = self.class.domain.foobara_domain_mapper_registry.lookup(from_type:, to_type:)
          mapper = mapper_class.new(from_value)
          mapper.call
        end

        def domain_map(from_value, from_type: nil, to_type: nil)
          mapper_class = self.class.domain.foobara_domain_mapper_registry.lookup(from_type:, to_type:)
          if mapper_class
            mapper = mapper_class.new(from_value)
            mapper.call
          end
        end
      end
    end
  end
end
