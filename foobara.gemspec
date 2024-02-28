require_relative "projects/version/src/version"

Gem::Specification.new do |spec|
  spec.name = "foobara"
  spec.version = Foobara::Version::VERSION
  spec.authors = ["Miles Georgi"]
  spec.email = ["azimux@gmail.com"]

  spec.summary = "Implements command pattern for encapsulating and managing domain complexity " \
                 "as well as many supporting libraries including entities."
  spec.description = spec.summary
  spec.homepage = "https://github.com/foobara/foobara"
  spec.license = "none yet"
  spec.required_ruby_version = ">= #{File.read("#{__dir__}/.ruby-version")}"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end

  spec.require_paths = Dir.glob("./projects/*/lib", base: __dir__)

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
