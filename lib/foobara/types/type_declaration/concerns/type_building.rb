module Foobara
  module Types
    class TypeDeclaration < Type
      module Concerns
        module TypeBuilding
          extend ActiveSupport::Concern

          def to_type
            declaration_data = to_h

            Types::AtomType.new(declaration_data, **to_type_args)
          end

          def to_type_args
            {
              casters:,
              value_transformers:,
              value_validators:
            }
          end

          def casters
            type_module_name = type.to_s.camelize.to_sym

            casters_module = Util.constant_value(Types::Casters, type_module_name)
            casters = Util.constant_values(casters_module, is_a: Class)

            direct_caster = casters.find { |caster| caster.name.to_sym == type_module_name }

            direct_caster = Array.wrap(direct_caster)

            casters -= direct_caster

            [*direct_caster, *casters].compact.map(&:instance)
          end

          def value_transformers
            transformers = []

            # we are an instance here so why do we pass in type??
            # TODO: make it so passing in type isn't necessary
            self.transformers.each_pair do |transformer_symbol, transformer_class|
              if strict_schema.key?(transformer_symbol)
                transformers << transformer_class.new(strict_schema[transformer_symbol])
              end
            end

            transformers
          end

          def value_validators
            validators = []

            self.validators.each_pair do |validator_symbol, validator_class|
              validator = validator_class.new(strict_schema[validator_symbol])

              validators << validator if validator.always_applicable?
            end

            validators
          end
        end
      end
    end
  end
end
