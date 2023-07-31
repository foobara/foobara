module Foobara
  class Outcome
    class << self
      def success(result)
        new.tap do |outcome|
          outcome.result = result
        end
      end

      def errors(*errors)
        if errors.length == 1
          errors = errors.first

          errors = if errors.is_a?(ErrorCollection)
                     errors.errors
                   else
                     Array.wrap(errors)
                   end
        end

        raise "No errors given" if errors.empty?

        new.tap do |outcome|
          errors.each { |error| outcome.add_error(error) }
        end
      end

      def error(error)
        errors(Array.wrap(error))
      end

      def raise!
        raise "kaboom" unless success?
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
      @result if success?
    end
  end
end
