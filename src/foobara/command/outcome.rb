module Foobara
  class Outcome
    class << self
      def success(result)
        new.tap do |outcome|
          outcome.result = result
        end
      end

      def errors(error_collection)
        if error_collection.is_a?(Array)
          new.tap do |outcome|
            error_collection.each do |error|
              outcome.add_error(error)
            end
          end
        else
          new(error_collection:)
        end
      end

      def error(error)
        errors(Array.wrap(error))
      end
    end

    attr_writer :result
    attr_reader :error_collection

    def initialize(error_collection: ErrorCollection.new)
      @error_collection = error_collection
    end

    delegate :has_errors?, :errors, :each_error, :has_error?, :add_error, to: :error_collection

    def success?
      !has_errors?
    end

    def result
      success? ? @result : nil
    end
  end
end
