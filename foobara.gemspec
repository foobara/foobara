require_relative "lib/foobara/version"

Gem::Specification.new do |spec|
  spec.name = "foobara"
  spec.version = Foobara::VERSION
  spec.authors = ["Miles Georgi"]
  spec.email = ["azimux@gmail.com"]

  spec.summary = "Implements command pattern for encapsulating and managing domain complexity " \
                 "as well as supporting libraries."
  spec.description = spec.summary
  spec.homepage = "https://github.com/foobara/foobara"
  spec.license = "none yet"
  spec.required_ruby_version = ">= 3.2.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  spec.add_runtime_dependency "activesupport"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = %w[
    common/lib
    builtin_types/lib
    value/lib
    enumerated/lib
    callback/lib
    state_machine/lib
    weak_object_set/lib
    thread_parent/lib
    types/lib
    type_declarations/lib
    command/lib
    lib
  ]

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
