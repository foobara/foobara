module Foobara
  class Command
    module Concerns
      module Reflection
        include Concern
        include Manifestable

        def initialize(...)
          self.class.all << self
          super(...)
        end

        module ClassMethods
          def all
            @all ||= []
          end

          def reset_all
            remove_instance_variable("@all") if instance_variable_defined?("@all")
          end

          def foobara_manifest(to_include:)
            depends = depends_on.map do |command_name|
              other_command = Foobara.foobara_lookup!(command_name, absolute: true)
              to_include << other_command
              other_command.foobara_manifest_reference
            end

            types = types_depended_on.select(&:registered?).map do |t|
              to_include << t
              t.foobara_manifest_reference
            end

            h = {
              types_depended_on: types,
              error_types: errors_type_declaration(to_include:),
              depends_on: depends,
              full_command_name:,
              # TODO: allow inputs type to be nil or really any type?
              inputs_type: inputs_type&.reference_or_declaration_data || {
                type: :attributes,
                element_type_declarations: {},
                required: []
              }
            }

            if result_type
              # TODO: find a way to represent literal types like "nil"
              h[:result_type] = result_type.reference_or_declaration_data
            end

            super.merge(h)
          end

          def command_name
            Util.non_full_name(self)
          end

          def types_depended_on
            types = if inputs_type
                      inputs_type.types_depended_on
                    else
                      Set.new
                    end

            unless depends_on_entities.empty?
              entity_types = depends_on_entities.map(&:entity_type)
              types |= entity_types
              types |= entity_types.map(&:types_depended_on).inject(:|)
            end

            if result_type
              types | result_type.types_depended_on
            else
              types
            end
          end
        end

        foobara_delegate :type_for_declaration, to: :class
      end
    end
  end
end
