=begin
module Foobara
  module TypeDeclarations
    class TypeDeclarationHandler < Value::Processor::Pipeline
      module Concerns
        module TypeBuilding
          extend ActiveSupport::Concern

          def to_type
            declaration_data = to_h

            # TODO: A little nervous to pass declaration data here... is that really necessary?
            Type.new(declaration_data, **to_type_args)
          end

          def to_type_args
            {
              casters:,
              transformers:,
              validators:
            }
          end

          def casters
            type_module_name = type.to_s.camelize.to_sym

            casters_module = Util.constant_value(BuiltinTypes::Casters, type_module_name)
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
            supported_transformer_classes.each_pair do |transformer_symbol, transformer_class|
              # we don't have a declaration type here!!!
              if strict_schema.key?(transformer_symbol)
                transformers << transformer_class.new(strict_schema[transformer_symbol])
              end
            end

            transformers
          end

          def value_validators
            validators = []

            supported_validator_classes.each_pair do |validator_symbol, validator_class|
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
=end
