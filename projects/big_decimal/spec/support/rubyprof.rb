RSpec.configure do |config|
  # TODO: move this to foobara-spec-helpers project
  config.around(:each, :profile) do |example|
    require "ruby-prof"
    RubyProf.start

    example.run

    result = RubyProf.stop
    printer = RubyProf::GraphHtmlPrinter.new(result)
    File.open("tmp/profile-out.html", "w+") do |file|
      printer.print(file)
    end
  end

  if ENV["RUBY_PROF"] == "true"
    config.before(:suite) do
      require "ruby-prof"
      require "ruby-prof/profile"
      RubyProf.start
    end

    config.after(:suite) do
      result = RubyProf.stop

      printer = RubyProf::GraphHtmlPrinter.new(result)
      File.open("tmp/profile-out.html", "w+") do |file|
        printer.print(file)
      end
    end
  end
end
