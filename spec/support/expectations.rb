module RspecHelpers
  module Expectations
    def is_expected_to_raise(*, &)
      is_expected_to raise_error(*, &)
    end

    def is_expected_to_not_raise(*, &)
      is_expected_to_not raise_error(*, &)
    end

    def is_expected_to(expectation)
      expect { subject }.to expectation
    end

    def is_expected_to_not(expectation)
      expect { subject }.to_not expectation
    end
  end
end

RSpec.configure do |c|
  c.include RspecHelpers::Expectations
end
