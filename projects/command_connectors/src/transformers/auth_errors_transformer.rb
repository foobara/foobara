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
              possible_error = PossibleError.new(CommandConnector::UnauthenticatedError)
              map = map.merge(possible_error.key.to_s => possible_error)
            end

            if transformed_command.allowed_rule
              possible_error = PossibleError.new(CommandConnector::NotAllowedError)
              map = map.merge(possible_error.key.to_s => possible_error)
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
