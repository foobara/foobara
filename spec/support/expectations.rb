module RspecHelpers
  module Expectations
    def is_expected_to_raise(*args)
      expect { subject }.to raise_error(*args)
    end
  end
end

RSpec.configure do |c|
  c.include RspecHelpers::Expectations
end
