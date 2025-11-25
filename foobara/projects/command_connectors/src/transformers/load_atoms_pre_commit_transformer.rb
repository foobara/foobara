require_relative "load_atoms_transformer"

module Foobara
  module CommandConnectors
    module Transformers
      class LoadAtomsPreCommitTransformer < LoadAtomsTransformer
        def applicable?(request)
          request.command.outcome.success?
        end

        def transform(request)
          super(request.command.outcome.result)

          request
        end
      end
    end
  end
end
