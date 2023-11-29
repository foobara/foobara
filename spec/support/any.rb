RSpec::Matchers.define :any do |expectation|
  match do |actual|
    actual.any? { |item| expectation === item }
  end

  failure_message do |actual|
    "expected that at least one element in #{actual} would match #{expected}"
  end
end
