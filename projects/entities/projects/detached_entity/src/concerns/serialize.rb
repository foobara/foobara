module Foobara
  class DetachedEntity < Model
    module Concerns
      module Serialize
        class CannotConvertRecordWithoutPrimaryKeyToJsonError < StandardError; end

        include Concern

        def inspect
          "<#{entity_name}:#{primary_key}>"
        end

        def to_json(*_args)
          primary_key&.to_json || raise(
            CannotConvertRecordWithoutPrimaryKeyToJsonError,
            "Cannot call record.to_json on unless record has a primary key. " \
            "Consider instead calling record.attributes.to_json instead."
          )
        end
      end
    end
  end
end
