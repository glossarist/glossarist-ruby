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

  spec.add_dependency "lutaml-model", "~> 0.8.15"
  # relaton-3.0.0.pre.alpha.5 resolves lutaml-store ~> 0.3.2; a 0.2
  # floor here made the pair unsolvable (2.14.0's activation
  # conflict).
  spec.add_dependency "lutaml-store", "~> 0.3"
  spec.add_dependency "paint", "~> 2.3"
  spec.add_dependency "rdf-turtle", "~> 3.3"
  spec.add_dependency "relaton", "~> 3.0.0.pre.alpha"
  spec.add_dependency "rubyzip", "~> 3.7"
  spec.add_dependency "shacl", "~> 0.4"
  # sts 0.6 (ISO-STS transformer wave) must resolve alongside this gem;
  # a ~> 0.5.6 cap broke every bundle pairing glossarist with
  # metanorma-oiml.
  spec.add_dependency "sts", ">= 0.5.6", "< 0.7"
  spec.add_dependency "table_tennis", "~> 0.0"
  spec.add_dependency "tbx", "~> 0.1"
  spec.add_dependency "thor"
end
