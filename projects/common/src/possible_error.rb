module Foobara
  class PossibleError
    attr_accessor :key, :error_class, :data, :processor

    def initialize(
      error_class,
      key: nil,
      data: nil,
      symbol: error_class.symbol,
      category: error_class.category,
      processor: nil
    )
      self.error_class = error_class
      self.processor = processor
      self.data = if data
                    data
                  elsif processor
                    { processor.symbol => processor.declaration_data }
                  end
      self.key = if key
                   if key.is_a?(ErrorKey)
                     key
                   else
                     ErrorKey.parse(key)
                   end
                 else
                   ErrorKey.new(symbol:, category:)
                 end
    end

    def dup
      PossibleError.new(
        error_class,
        key: key.dup,
        data:
      )
    end

    def prepend_path!(...)
      key.prepend_path!(...)
    end

    def prepend_runtime_path!(...)
      key.prepend_runtime_path!(...)
    end

    # TODO: technically does not belong in this project but maybe it should
    def foobara_manifest(to_include:)
      to_include << error_class

      if processor
        processor_class = processor.class
        to_include << processor_class

        if processor.scoped_path_set?
          # Unclear why nothing in the test suite passes through here.
          # TODO: either test this or delete it.
          # :nocov:
          to_include << processor
          processor_reference = processor.foobara_manifest_reference
          # :nocov:
        end
      end

      key.to_h.merge(
        key: key.to_s,
        error: error_class.foobara_manifest_reference,
        processor: processor_reference,
        processor_class: processor_class&.foobara_manifest_reference,
        data:
      )
    end
  end
end
