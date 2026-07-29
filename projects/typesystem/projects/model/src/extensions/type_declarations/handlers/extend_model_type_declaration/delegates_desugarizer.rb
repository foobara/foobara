module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class DelegatesDesugarizer < TypeDeclarations::Desugarizer
          def applicable?(sugary_type_declaration)
            sugary_type_declaration.key?(:delegates) && sugary_type_declaration[:delegates].is_a?(::Hash)
          end

          def desugarize(sugary_type_declaration)
            delegates = sugary_type_declaration[:delegates]

            if delegates.empty?
              sugary_type_declaration.delete(:delegates)
            else
              delegates = Util.deep_symbolize_keys(sugary_type_declaration[:delegates])

              delegates.each_pair do |attribute_name, delegate_info|
                h = delegate_info.merge(data_path: DataPath.new(delegate_info[:data_path]).to_s)

                no_writer = !delegate_info[:writer]

                if no_writer
                  h.delete(:writer)
                else
                  h[:writer] = true
                end

                delegates[attribute_name] = h
              end

              sugary_type_declaration[:delegates] = delegates
            end

            sugary_type_declaration
          end
        end
      end
    end
  end
end
