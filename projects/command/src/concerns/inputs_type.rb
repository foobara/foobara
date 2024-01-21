module Foobara
  class Command
    module Concerns
      module InputsType
        include Concern

        module ClassMethods
          def inputs(*args, &block)
            if block && !args.empty?
              # :nocov:
              raise "Cannot provide both block and declaration"
              # :nocov:
            end

            inputs_type_declaration = if block
                                        Foobara::TypeDeclarations::Dsl::Attributes.to_declaration(&block)
                                      elsif args.size == 1
                                        args.first
                                      else
                                        # :nocov:
                                        raise ArgumentError,
                                              "expected 1 argument or a block but got #{args.size} arguments"
                                        # :nocov:
                                      end

            @inputs_type = type_for_declaration(inputs_type_declaration)

            register_possible_input_errors

            @inputs_type
          end

          def inputs_type
            return @inputs_type if defined?(@inputs_type)

            @inputs_type = if superclass < Foobara::Command
                             superclass.inputs_type
                           end
          end

          def raw_inputs_type_declaration
            inputs_type.raw_declaration_data
          end

          def inputs_type_declaration
            inputs_type.declaration_data
          end

          private

          def register_possible_input_errors
            # TODO: let's derive these at runtime and memoize...
            inputs_type.possible_errors.each_pair do |key, error_class|
              register_possible_error_class(key, error_class)
            end
          end
        end

        foobara_delegate :inputs_type, :raw_inputs_type_declaration, to: :class
      end
    end
  end
end
