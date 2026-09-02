module Foobara
  class CommandRegistry
    module ExposedCommandEntities
      def initialize(
        command_class,
        pre_commit_transformers: nil,
        serializers: nil,
        aggregate_entities: nil,
        atomic_entities: nil,
        **
      )
        if aggregate_entities
          pre_commit_transformers = [
            *pre_commit_transformers,
            CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer
          ]

          pre_commit_transformers.uniq!
          pre_commit_transformers.delete(CommandConnectors::Transformers::LoadAtomsPreCommitTransformer)

          serializers = [*serializers, CommandConnectors::Serializers::AggregateSerializer]

          serializers.uniq!
          serializers.delete(Foobara::CommandConnectors::Serializers::AtomicSerializer)
          # TODO: either both should have special behavior for false or neither should
        elsif aggregate_entities == false
          pre_commit_transformers = pre_commit_transformers&.reject do |t|
            t == Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer
          end
          serializers = serializers&.reject do |s|
            s == Foobara::CommandConnectors::Serializers::AggregateSerializer
          end
        elsif atomic_entities
          pre_commit_transformers = [
            *pre_commit_transformers,
            CommandConnectors::Transformers::LoadAtomsPreCommitTransformer
          ]

          pre_commit_transformers.uniq!
          pre_commit_transformers.delete(CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer)

          serializers = [*serializers, Foobara::CommandConnectors::Serializers::AtomicSerializer]

          serializers.uniq!
          serializers.delete(CommandConnectors::Serializers::AggregateSerializer)
        end

        # A bit hacky... we should check if we need to shim in a LoadDelegatedAttributesEntitiesPreCommitTransformer
        unless aggregate_entities
          # It's possible delegates have been added or removed via the result transformers...
          # We should figure out a way to check the transformed result type instead.
          if _has_delegated_attributes?(command_class.result_type)
            pre_commit_transformers = [
              *pre_commit_transformers,
              CommandConnectors::Transformers::LoadDelegatedAttributesEntitiesPreCommitTransformer
            ]

            pre_commit_transformers.uniq!
          end
        end

        super(
          command_class,
          pre_commit_transformers:,
          serializers:,
          **
        )
      end
    end
  end
end
