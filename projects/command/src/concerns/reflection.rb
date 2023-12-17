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

            types = types_depended_on.map do |t|
              to_include << t
              t.foobara_manifest_reference
            end

            inputs_types_depended_on = self.inputs_types_depended_on.map do |t|
              to_include << t
              t.foobara_manifest_reference
            end

            result_types_depended_on = self.result_types_depended_on.map do |t|
              to_include << t
              t.foobara_manifest_reference
            end

            errors_types_depended_on = self.errors_types_depended_on.map do |t|
              to_include << t
              t.foobara_manifest_reference
            end

            h = {
              types_depended_on: types,
              inputs_types_depended_on:,
              result_types_depended_on:,
              errors_types_depended_on:,
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
            @types_depended_on ||= begin
              types = inputs_types_depended_on | result_types_depended_on | errors_types_depended_on

              unless depends_on_entities.empty?
                entity_types = depends_on_entities.map(&:entity_type)
                types |= entity_types
                types |= entity_types.map(&:types_depended_on).inject(:|)
              end

              types
            end
          end

          def inputs_types_depended_on
            @inputs_types_depended_on ||= if inputs_type
                                            if inputs_type.registered?
                                              # TODO: if we ever change from attributes-only inputs type
                                              # then this will be handy
                                              # :nocov:
                                              Set[inputs_type]
                                              # :nocov:
                                            else
                                              inputs_type.types_depended_on
                                            end
                                          else
                                            Set.new
                                          end
          end

          def result_types_depended_on
            @result_types_depended_on ||= if result_type
                                            if result_type.registered?
                                              Set[result_type]
                                            else
                                              result_type.types_depended_on
                                            end
                                          else
                                            Set.new
                                          end
          end

          def errors_types_depended_on
            @errors_types_depended_on ||= error_context_type_map.values.map(&:types_depended_on).inject(:|) || Set.new
          end
        end

        foobara_delegate :type_for_declaration, to: :class
      end
    end
  end
end
