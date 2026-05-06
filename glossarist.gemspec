# frozen_string_literal: true

require_relative "lib/glossarist/version"

all_files_in_git = Dir.chdir(File.expand_path(__dir__)) do
  `git ls-files -z`.split("\x0")
end

Gem::Specification.new do |spec|
  spec.name          = "glossarist"
  spec.version       = Glossarist::VERSION
  spec.authors       = ["Ribose"]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       =
    "Concept models for terminology glossaries conforming ISO 10241-1."
  spec.homepage      = "https://github.com/glossarist/glossarist-ruby"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files         = all_files_in_git
    .reject { |f| f.match(%r{\A(?:test|spec|features|bin|\.)/}) }

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lutaml-model", "~> 0.8.5"
  spec.add_dependency "relaton", ">= 2.0.0", "< 3"
  spec.add_dependency "rubyzip", ">= 2.3", "< 3"
  spec.add_dependency "tbx", "~> 0.1"
  spec.add_dependency "thor"
end
