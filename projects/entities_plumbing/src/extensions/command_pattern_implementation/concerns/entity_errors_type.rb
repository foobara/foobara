module Foobara
  module CommandPatternImplementation
    module Concerns
      module EntityErrorsType
        include Concern

        module ClassMethods
          def inputs(...)
            if defined?(@inputs_association_paths)
              remove_instance_variable(:@inputs_association_paths)
            end

            super
          end

          def error_context_type_map
            return @error_context_type_map if defined?(@error_context_type_map)

            super

            inputs_association_paths&.each do |data_path|
              possible_input_error(data_path.to_sym, CommandPatternImplementation::NotFoundError)
            end

            @error_context_type_map
          end
        end
      end
    end
  end
end
