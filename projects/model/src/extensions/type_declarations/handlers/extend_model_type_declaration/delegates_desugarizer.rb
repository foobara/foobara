module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class DelegatesDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.key?(:delegates) && sugary_type_declaration[:delegates].is_a?(::Hash)
          end

          def desugarize(sugary_type_declaration)
            desugarized = Util.deep_dup(sugary_type_declaration[:delegates])

            if desugarized.empty?
              desugarized.delete(:delegates)
            else
              desugarized.each_pair do |attribute_name, delegate_info|
                h = delegate_info.merge(data_path: DataPath.new(delegate_info[:data_path]).to_s)

                no_writer = !delegate_info[:writer]

                if no_writer
                  h.delete(:writer)
                else
                  h[:writer] = true
                end

                desugarized[attribute_name] = h
              end
            end

            sugary_type_declaration.merge(delegates: desugarized)
          end
        end
      end
    end
  end
end
