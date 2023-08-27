module RspecHelpers
  module Expectations
    def is_expected_to_raise(*, &)
      # expect { subject }.to raise_error(*, &)
      is_expected_to raise_error(*, &)
    end

    def is_expected_to(expectation)
      expect { subject }.to expectation
    end
  end
end

RSpec.configure do |c|
  c.include RspecHelpers::Expectations
end
