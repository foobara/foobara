module Foobara
  module BuiltinTypes
    module Entity
      module SupportedTransformers
        class Mutable < Model::SupportedTransformers::Mutable
          module TypeDeclarationExtension
            module ExtendEntityTypeDeclaration
              module TypeDeclarationValidators
                # TODO: why do we have to create a version in Entity for this validator but not the desugarizer??
                class ValidAttributeNames < Model::SupportedTransformers::Mutable::TypeDeclarationExtension::
                    ExtendModelTypeDeclaration::TypeDeclarationValidators::ValidAttributeNames
                end
              end
            end
          end
        end
      end
    end
  end
end
