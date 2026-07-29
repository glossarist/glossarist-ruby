# frozen_string_literal: true

require "rdf/turtle"
require "shacl"
require "pathname"
# Entry-point require triggers the autoload chain
# (Glossarist → Validation → ShaclValidator). Internal-path requires
# are forbidden by the autoload rule.
require "glossarist"

namespace :glossarist do
  desc "Validate all .ttl outputs against concept-model SHACL shapes. " \
       "Pass path=root_dir or shapes=path/to/shapes.ttl."
  task :shacl, [:path] do |_t, args|
    shapes = args[:shapes] || ENV.fetch("SHAPES_PATH", nil)
    root   = args[:path] || ENV.fetch("SHACL_PATH", "compiled")

    files = Pathname.glob("#{root}/**/*.ttl")
    if files.empty?
      warn "No .ttl files found under #{root}"
      exit 1
    end

    validator = Glossarist::Validation::ShaclValidator.new(shapes_path: shapes)
    report = validator.validate_files(files.map(&:to_s))
    if report.conformant?
      puts "All #{files.length} .ttl file(s) conform to SHACL shapes."
    else
      warn report.to_s
      exit 1
    end
  end
end
