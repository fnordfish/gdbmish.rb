# frozen_string_literal: true

require_relative "lib/gdbmish/version"

Gem::Specification.new do |spec|
  spec.name = "gdbmish"
  spec.version = Gdbmish::VERSION
  spec.authors = ["Robert Schulze"]
  spec.email = ["robert@dotless.de"]

  spec.summary = "Create and read GDBM dump files."
  spec.description = <<~DESC.gsub(/\n+/, " ").strip
    GDBM database files are not portable between different architectures.
    This gem reimplements the `gdbm_dump` and `gdbm_load` ASCII format in
    pure Ruby to allow for easy creation and reading of portable GDBM dump
    files.
  DESC
  spec.homepage = "https://github.com/fnordfish/gdbmish.rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  # spec.bindir = "exe"
  # spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if RUBY_ENGINE != "jruby"
    spec.add_dependency "stringio"
    spec.add_dependency "base64"
    spec.add_dependency "time"
  end
end
