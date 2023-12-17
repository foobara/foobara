module Foobara
  module CommandConnectors
    module Transformers
      # This behavior is hard-coded but this is here to update the error classes in the manifest
      class AuthErrorsTransformer < Value::Transformer
        class << self
          # Feels awkward to have to do this for a few reasons. Passing self and also not
          # adhering to processor interface. Not sure how best to address this.
          def transform_error_context_type_map(transformed_command, map)
            if transformed_command.requires_authentication
              map = map.merge("runtime.unauthenticated" => CommandConnector::UnauthenticatedError)
            end

            if transformed_command.allowed_rule
              map = map.merge("runtime.not_allowed" => CommandConnector::NotAllowedError)
            end

            map
          end
        end
        def applicable?(_request)
          false
        end

        def transform(_request)
          # :nocov:
          raise "Not expected to be called"
          # :nocov:
        end
      end
    end
  end
end
