Foobara.require_project_file("type_declarations", "to_type_transformer")

module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        # TODO: seems like we have more base classes than we need
        class ToTypeTransformer < TypeDeclarations::ToTypeTransformer
          def transform(strict_type_declaration)
            strict_type_declaration.is_strict = true
            registered_type(strict_type_declaration)
          end

          def type_symbol(strict_type_declaration)
            strict_type_declaration[:type]
          end

          def registered_type(strict_type_declaration)
            symbol = type_symbol(strict_type_declaration)
            if strict_type_declaration.strict? || strict_type_declaration.strict_stringified?
              symbol = "::#{symbol}"
            else
              raise "wtf isn't this guaranteed to be strict?"
            end
            # TODO: lookup in absolute mode instead...
            # TODO: use declaration as a place to cache the type
            if symbol.to_s =~ /AuthUser/
              binding.pry if lookup_type(symbol).nil?
              # $stop = true
            end
            lookup_type!(symbol)
          rescue => e
            binding.pry
            raise
          end

          def target_classes(strict_type_declaration)
            registered_type(strict_type_declaration).target_classes
          end
        end
      end
    end
  end
end
