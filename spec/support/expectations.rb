module RspecHelpers
  module Expectations
    def is_expected_to_raise(*)
      expect { subject }.to raise_error(*)
    end
  end
end

RSpec.configure do |c|
  c.include RspecHelpers::Expectations
end
