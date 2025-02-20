module Foobara
  module CommandPatternImplementation
    module Concerns
      module DomainMappers
        class ForgotToDependOnDomainMapperError < Foobara::RuntimeError
          context { mapper_name :string, :required }

          attr_accessor :mapper

          def initialize(mapper)
            self.mapper = mapper
            super()
          end

          def context
            { mapper_name: mapper.name }
          end

          def message
            "Did you maybe forget to add depends_on #{mapper.name}?"
          end
        end

        class NoDomainMapperFoundError < Foobara::RuntimeError
          context do
            subcommand_name :string, :required
            to :duck
          end

          attr_accessor :subcommand, :to

          def initialize(subcommand, to)
            self.subcommand = subcommand
            self.to = to

            super()
          end

          def context
            { subcommand_name: subcommand.name, to: }
          end

          def message
            "No DomainMapper found that maps to #{subcommand.name} or from its result"
          end
        end

        include Concern

        def run_mapped_subcommand!(subcommand_class, unmapped_inputs = {}, to = nil)
          mapped_something = false
          no_mapper_found = nil

          criteria = ->(mapper) { self.class.depends_on?(mapper) }

          inputs_mapper = self.class.domain.lookup_matching_domain_mapper(
            from: unmapped_inputs,
            to: subcommand_class,
            criteria:,
            strict: true
          )

          inputs = if inputs_mapper
                     mapped_something = true
                     run_subcommand!(inputs_mapper, from: unmapped_inputs)
                   else
                     unmapped_inputs
                   end

          result_mapper = if subcommand_class.result_type
                            mapper = self.class.domain.lookup_matching_domain_mapper(
                              from: subcommand_class.result_type,
                              to:,
                              criteria:,
                              strict: true
                            )

                            no_mapper_found = mapper.nil? && inputs_mapper.nil?

                            mapper
                          end

          result = unless no_mapper_found
                     run_subcommand!(subcommand_class, inputs)
                   end

          unless subcommand_class.result_type
            result_mapper = self.class.domain.lookup_matching_domain_mapper(
              from: result,
              to:,
              criteria: ->(domain_mapper) { self.class.depends_on?(domain_mapper) },
              strict: true
            )
          end

          if result_mapper
            mapped_something = true
            result = run_subcommand!(result_mapper, from: result)
          end

          unless mapped_something
            mapper = self.class.domain.lookup_matching_domain_mapper(
              from: unmapped_inputs,
              to: subcommand_class,
              strict: true
            )

            if mapper
              raise ForgotToDependOnDomainMapperError, mapper
            end

            mapper = self.class.domain.lookup_matching_domain_mapper(
              from: subcommand_class.result_type,
              to:,
              strict: true
            )

            if mapper
              raise ForgotToDependOnDomainMapperError, mapper
            end

            raise NoDomainMapperFoundError.new(subcommand_class, to)
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
