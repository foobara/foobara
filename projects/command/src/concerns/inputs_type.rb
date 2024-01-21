module Foobara
  class Command
    module Concerns
      module InputsType
        include Concern

        module ClassMethods
          def inputs(*args, &block)
            @inputs_type = case args.size
                           when 0
                             unless block
                               # :nocov:
                               raise ArgumentError, "expected 1 argument or a block but got 0 arguments and no block"
                               # :nocov:
                             end

                             declaration = Foobara::TypeDeclarations::Dsl::Attributes.to_declaration(&block)
                             type_for_declaration(declaration)
                           when 1
                             if block
                               # :nocov:
                               raise ArgumentError, "Cannot provide both block and declaration"
                               # :nocov:
                             end

                             type = args.first

                             if type.is_a?(Types::Type)
                               type
                             else
                               type_for_declaration(type)
                             end
                           else
                             # :nocov:
                             raise ArgumentError, "expected 0 or 1 argument but got #{args.size} arguments"
                             # :nocov:
                           end

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
