Foobara.require_project_file("type_declarations", "desugarizer")
Foobara.require_project_file("type_declarations", "handlers/extend_associative_array_type_declaration")
Foobara.require_project_file("type_declarations", "handlers/extend_attributes_type_declaration/hash_desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendArrayTypeDeclaration < ExtendAssociativeArrayTypeDeclaration
        # TODO: make a quick way to convert a couple simple procs into a transformer
        class ElementTypeDeclarationsDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            raise "implement"
            return false unless sugary_type_declaration.is_a?(::Hash)
            return false unless Util.all_symbolizable_keys?(sugary_type_declaration)

            sugary_type_declaration = Util.symbolize_keys(sugary_type_declaration)

            return true unless sugary_type_declaration.key?(:type)

            type_symbol = sugary_type_declaration[:type]

            if type_symbol == :attributes
              Util.all_symbolizable_keys?(sugary_type_declaration[:element_type_declarations])
            elsif type_symbol.is_a?(::Symbol)
              !type_registered?(type_symbol)
            end
          end

          def desugarize(sugary_type_declaration)
            binding.pry
            sugary_type_declaration[:element_type_declarations].transform_values! do |element_type_declaration|
              handler = type_declaration_handler_for(element_type_declaration)
              handler.desugarize(element_type_declaration)
            end

            sugary_type_declaration
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
