module Foobara
  module Common
    class Outcome
      class UnsuccessfulOutcomeError < StandardError
        attr_accessor :errors

        def initialize(errors)
          self.errors = errors

          message = errors.map(&:message).join(", ")

          super(message)
        end
      end

      class << self
        def success(result)
          new.tap do |outcome|
            outcome.result = result
          end
        end

        def errors(*errors)
          errors = errors.flatten

          if errors.blank?
            # :nocov:
            raise "No errors given"
            # :nocov:
          end

          new.tap do |outcome|
            outcome.add_errors(errors)
          end
        end

        def error(error)
          errors(Array.wrap(error))
        end

        def raise!(errors)
          self.errors(errors).raise! if errors.present?
        end
      end

      attr_accessor :result
      attr_reader :error_collection

      def initialize(result: nil, errors: nil, error_collection: ErrorCollection.new)
        @error_collection = error_collection

        self.result = result

        if errors.present?
          add_errors(errors)
        end
      end

      delegate :has_errors?,
               :errors,
               :each_error,
               :has_error?,
               :add_error,
               :add_errors,
               to: :error_collection

      def success?
        !has_errors?
      end

      def raise!
        return if success?

        if errors.size == 1
          raise errors.first
        else
          raise UnsuccessfulOutcomeError, errors
        end
      end

      def symbolic_errors
        error_collection.symbolic
      end
    end
  end
end
