# frozen_string_literal: true

require_relative "lib/fake_sonic_pi/version"

Gem::Specification.new do |spec|
  spec.name = "fake_sonic_pi"
  spec.version = FakeSonicPi::VERSION
  spec.authors = ["Sergio Gil"]
  spec.email = ["sgilperez@gmail.com"]

  spec.summary = "Support library to write tests for Sonic Pi code"
  spec.description = "fake_sonic_pi is a reimplementation of a small subset of the Sonic Pi"
  spec.homepage = "https://github.com/porras/fake_sonic_pi"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
