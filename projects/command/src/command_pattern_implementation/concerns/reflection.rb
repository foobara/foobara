module Foobara
  module CommandPatternImplementation
    module Concerns
      module Reflection
        include Concern
        include Manifestable

        def initialize(...)
          self.class.all << self
          super
        end

        module ClassMethods
          def all
            @all ||= []
          end

          def reset_all
            remove_instance_variable("@all") if instance_variable_defined?("@all")
          end

          def foobara_manifest(to_include: Set.new, remove_sensitive: false)
            depends_on = self.depends_on.map do |command_name|
              other_command = Foobara::Namespace.global.foobara_lookup!(command_name,
                                                                        mode: Foobara::Namespace::LookupMode::ABSOLUTE)
              to_include << other_command
              other_command.foobara_manifest_reference
            end.sort

            types = types_depended_on.map do |t|
              to_include << t
              t.foobara_manifest_reference
            end.sort

            inputs_types_depended_on = self.inputs_types_depended_on.map do |t|
              to_include << t
              t.foobara_manifest_reference
            end.sort

            result_types_depended_on = self.result_types_depended_on.map do |t|
              to_include << t
              t.foobara_manifest_reference
            end.sort

            errors_types_depended_on = self.errors_types_depended_on.map do |t|
              to_include << t
              t.foobara_manifest_reference
            end.sort

            possible_errors = self.possible_errors.map do |possible_error|
              [possible_error.key.to_s, possible_error.foobara_manifest(to_include:)]
            end.sort.to_h

            h = Util.remove_blank(
              types_depended_on: types,
              inputs_types_depended_on:,
              result_types_depended_on:,
              errors_types_depended_on:,
              possible_errors:,
              depends_on:,
              # TODO: allow inputs type to be nil or really any type?
              inputs_type: inputs_type&.reference_or_declaration_data || {
                type: "::attributes",
                element_type_declarations: {},
                required: []
              }
            ).merge(description:)

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
            # TODO: is there a simpler way to wrap these methods in this namespace?
            # something aspect-oriented-ish?
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
            @errors_types_depended_on ||= begin
              error_classes = possible_errors.map(&:error_class)
              error_classes.map(&:types_depended_on).inject(:|) || Set.new
            end
          end
        end

        foobara_delegate :type_for_declaration, to: :class
      end
    end
  end
end
