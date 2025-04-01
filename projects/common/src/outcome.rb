module Foobara
  class Outcome
    class UnsuccessfulOutcomeError < StandardError
      attr_accessor :errors, :backtrace_when_raised

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

        if errors.empty?
          # :nocov:
          raise "No errors given"
          # :nocov:
        end

        new.tap do |outcome|
          outcome.add_errors(errors)
        end
      end

      def error(error)
        errors(Util.array(error))
      end

      def raise!(errors)
        self.errors(errors).raise! unless errors.empty?
      end
    end

    attr_accessor :result
    attr_reader :error_collection

    def initialize(result: nil, errors: nil, error_collection: ErrorCollection.new)
      @error_collection = error_collection

      self.result = result

      if errors
        add_errors(errors)
      end
    end

    foobara_delegate :has_errors?,
                     :errors,
                     :each_error,
                     :has_error?,
                     :add_error,
                     :add_errors,
                     to: :error_collection

    def success?
      !has_errors?
    end

    def fatal?
      errors.any?(&:fatal?)
    end

    def raise!
      return if success?

      error = errors.first
      original_backtrace = error.backtrace_when_initialized

      if errors.size > 1
        error = UnsuccessfulOutcomeError.new(errors)
      end

      error.set_backtrace(original_backtrace)
      error.backtrace_when_raised = caller

      raise error
    end

    def result!
      raise!
      result
    end

    def errors_hash
      error_collection.to_h
    end

    def errors_sentence
      error_collection.to_sentence
    end

    def error_keys
      error_collection.keys
    end
  end
end
