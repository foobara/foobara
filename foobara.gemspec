require_relative "version"

Gem::Specification.new do |spec|
  spec.name = "foobara"
  spec.version = Foobara::Version::VERSION
  spec.authors = ["Miles Georgi"]
  spec.email = ["azimux@gmail.com"]

  spec.summary = "A command-centric and discoverable software framework with a focus on domain concepts " \
                 "and abstracting away integration code"
  spec.description = spec.summary
  spec.homepage = "https://foobara.org"
  spec.license = "MPL-2.0"
  spec.required_ruby_version = Foobara::Version::MINIMUM_RUBY_VERSION

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/foobara/foobara"
  spec.metadata["changelog_uri"] = "#{spec.metadata["source_code_uri"]}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "projects/**/*",
    "version.rb",
    "LICENSE*.txt",
    "README.md",
    "CHANGELOG.md",
    ".ruby-version"
  ]

  spec.require_paths = [
    *Dir.glob("projects/typesystem/projects/*/lib", base: __dir__),
    *Dir.glob("projects/entities/projects/*/lib", base: __dir__),
    *Dir.glob("projects/command/lib", base: __dir__),
    *Dir.glob("projects/domain_mapper/lib", base: __dir__),
    *Dir.glob("projects/command_connectors/lib", base: __dir__),
    *Dir.glob("projects/manifest/lib", base: __dir__),
    *Dir.glob("projects/foobara/lib", base: __dir__)
  ]

  spec.add_dependency "bigdecimal"
  spec.add_dependency "foobara-lru-cache", "< 2.0.0"
  spec.add_dependency "foobara-util", "< 2.0.0"
  spec.add_dependency "inheritable-thread-vars", "< 2.0.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
