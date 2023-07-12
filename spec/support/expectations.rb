module RspecHelpers
  module Expectations
    def is_expected_to_raise(error_class)
      expect { subject }.to raise_error(error_class)
    end
  end
end

RSpec.configure do |c|
  c.include RspecHelpers::Expectations
end
