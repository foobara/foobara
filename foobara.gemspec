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
  spec.license = "AGPL-3.0"
  spec.required_ruby_version = ">= #{File.read("#{__dir__}/.ruby-version")}"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  spec.files = Dir[
    "projects/**/*",
    "LICENSE*.txt",
    "README.md",
    "CHANGELOG.md"
  ]

  spec.require_paths = Dir.glob("./projects/*/lib", base: __dir__)

  spec.add_dependency "foobara-util"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
