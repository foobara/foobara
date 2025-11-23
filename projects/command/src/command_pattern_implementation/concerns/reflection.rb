module Foobara
  module CommandPatternImplementation
    module Concerns
      module Reflection
        include Concern
        include Manifestable

        module ClassMethods
          def foobara_manifest
            to_include = TypeDeclarations.foobara_manifest_context_to_include

            depends_on = self.depends_on.map do |command_name|
              other_command = Foobara::Namespace.global.foobara_lookup!(
                command_name,
                mode: Foobara::Namespace::LookupMode::ABSOLUTE_SINGLE_NAMESPACE
              )
              if to_include
                to_include << other_command
              end
              other_command.foobara_manifest_reference
            end.sort

            types = types_depended_on.map do |t|
              if to_include
                to_include << t
              end
              t.foobara_manifest_reference
            end.sort

            inputs_types_depended_on = self.inputs_types_depended_on.map do |t|
              if to_include
                to_include << t
              end
              t.foobara_manifest_reference
            end.sort

            result_types_depended_on = self.result_types_depended_on.map do |t|
              if to_include
                to_include << t
              end
              t.foobara_manifest_reference
            end.sort

            errors_types_depended_on = self.errors_types_depended_on.map do |t|
              if to_include
                to_include << t
              end
              t.foobara_manifest_reference
            end.sort

            possible_errors = self.possible_errors.map do |possible_error|
              [possible_error.key.to_s, possible_error.foobara_manifest]
            end.sort.to_h

            h = Util.remove_blank(
              types_depended_on: types,
              inputs_types_depended_on:,
              result_types_depended_on:,
              errors_types_depended_on:,
              possible_errors:,
              depends_on:,
              # TODO: allow inputs type to be nil or really any type?
              inputs_type: inputs_type&.reference_or_declaration_data || GlobalDomain.foobara_type_from_declaration(
                type: "::attributes",
                element_type_declarations: {},
                required: []
              ).declaration_data
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
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            if defined?(@types_depended_on) && @types_depended_on.key?(remove_sensitive)
              return @types_depended_on[remove_sensitive]
            end

            @types_depended_on ||= {}
            @types_depended_on[remove_sensitive] = begin
              types = inputs_types_depended_on |
                      result_types_depended_on |
                      errors_types_depended_on

              unless depends_on_entities.empty?
                entity_types = depends_on_entities.map(&:entity_type)

                if remove_sensitive
                  entity_types = entity_types.reject(&:sensitive?)
                end

                types |= entity_types
                types |= entity_types.map(&:types_depended_on).inject(:|)
              end

              types
            end
          end

          def inputs_types_depended_on
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            if defined?(@inputs_types_depended_on) && @inputs_types_depended_on.key?(remove_sensitive)
              return @inputs_types_depended_on[remove_sensitive]
            end

            @inputs_types_depended_on ||= {}
            @inputs_types_depended_on[remove_sensitive] = if inputs_type
                                                            if inputs_type.registered?
                                                              # TODO: if we ever change from attributes-only inputs type
                                                              # then this will be handy
                                                              # :nocov:
                                                              if !remove_sensitive || !inputs_type.sensitive?
                                                                Set[inputs_type]
                                                              else
                                                                Set.new
                                                              end
                                                              # :nocov:
                                                            else
                                                              inputs_type.types_depended_on
                                                            end
                                                          else
                                                            Set.new
                                                          end
          end

          def result_types_depended_on
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            if defined?(@result_types_depended_on) && @result_types_depended_on.key?(remove_sensitive)
              return @result_types_depended_on[remove_sensitive]
            end

            @result_types_depended_on ||= {}
            @result_types_depended_on[remove_sensitive] = if result_type
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
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            if defined?(@errors_types_depended_on) && @errors_types_depended_on.key?(remove_sensitive)
              return @errors_types_depended_on[remove_sensitive]
            end

            @errors_types_depended_on ||= {}
            @errors_types_depended_on[remove_sensitive] = begin
              error_classes = possible_errors.map(&:error_class)
              error_classes.map(&:types_depended_on).inject(:|) || Set.new
            end
          end
        end
      end
    end
  end
end
