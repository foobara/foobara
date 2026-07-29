module Foobara
  module TypeDeclarations
    module Handlers
      class RegisteredTypeDeclaration < TypeDeclarationHandler
        class ValidatePrimaryKeyPresent < TypeDeclarations::TypeDeclarationValidator
          # TODO: seems like maybe we could actually check against types now...
          # like make a type for primary_key: :symbol ??
          class MissingPrimaryKeyError < TypeDeclarationError; end

          def validation_errors(type_declaration)
            if type_declaration.claimed_but_error?
              klass = type_declaration.declaration_data

              if klass.is_a?(::Class) && klass < ::Foobara::DetachedEntity
                if klass.model_type.nil? && klass.primary_key_attribute.nil?
                  build_error(
                    message: "#{klass} doesn't have a primary key attribute set yet. " \
                             "Did you forget something like `primary_key :id` in #{klass}?"
                  )
                end
              end
            end
          end

          def error_context(_value) ={}
        end
      end
    end
  end
end
