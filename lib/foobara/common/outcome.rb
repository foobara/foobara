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

      def merge(outcomes)
        raise unless outcomes.present?

        success_outcomes, error_outcomes = outcomes.partition(&:success?)

        if error_outcomes.any?
          unmerged_errors = error_outcomes.map(&:errors).flatten
          merged_errors = unmerged_errors.group_by(&:symbol).values.map do |errors|
            if errors.length > 1
              MultipleError.new(errors)
            else
              errors.first
            end
          end

          Outcome.errors(merged_errors)
        else
          Outcome.success(success_outcomes.map(&:result))
        end
      end
    end

    attr_writer :result
    attr_reader :error_collection
    attr_accessor :keep_result_even_if_not_success

    def initialize(error_collection: ErrorCollection.new, keep_result_even_if_not_success: false)
      self.keep_result_even_if_not_success = keep_result_even_if_not_success
      @error_collection = error_collection
    end

    delegate :has_errors?, :errors, :each_error, :has_error?, :add_error, to: :error_collection

    def success?
      !has_errors?
    end

    def result
      if success? || keep_result_even_if_not_success
        @result
      end
    end
  end
end
