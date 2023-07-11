guard :rspec, all_after_pass: true, all_on_start: true, cmd: "bundle exec rspec", failed_mode: :focus do
  watch(%r{^spec/(.+)_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/spec_helper.rb$}) { "spec/" }
  watch(/^load_everything.rb$/) { "spec/" }
end
