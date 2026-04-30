# frozen_string_literal: true

require "thor"

module Glossarist
  class CLI < Thor
    desc "generate_latex", "Convert Concepts to Latex format"

    option :concepts_path, aliases: :p, required: true,
                           desc: "Path to yaml concepts directory"
    option :latex_concepts, aliases: :l,
                            desc: "File path having list of concepts that should be converted to LATEX format. If not provided all the concepts will be converted to the latex format"
    option :output_file, aliases: :o,
                         desc: "Output file path. By default the output will pe printed to the console"
    option :extra_attributes, aliases: :e, type: :array,
                              desc: "List of extra attributes that are not in standard Glossarist Concept model"
    def generate_latex
      assets = []

      if options[:extra_attributes]
        Glossarist.configure do |config|
          config.register_extension_attributes(options[:extra_attributes])
        end
      end

      concept_set = Glossarist::ConceptSet.new(options[:concepts_path], assets)
      latex_str = concept_set.to_latex(options[:latex_concepts])
      output_latex(latex_str)
    end

    desc "upgrade SOURCE_DIR", "Upgrade dataset to current schema version"
    option :output, aliases: :o, required: true,
                   desc: "Output directory or .gcr file path"
    option :target_version, type: :string, default: Glossarist::SchemaMigration::CURRENT_SCHEMA_VERSION,
                           desc: "Target schema version (default: current)"
    option :cross_references, type: :string,
                             desc: "Path to datasets.yml for cross-reference maps"
    option :dry_run, type: :boolean, default: false,
                    desc: "Show what would change without writing"
    def upgrade(source_dir)
      require_relative "cli/upgrade_command"
      Glossarist::CLI::UpgradeCommand.new(source_dir, options).run
    end

    desc "package DIR", "Create a .gcr ZIP archive from a schema v1 dataset"
    option :output, aliases: :o, required: true,
                   desc: "Output .gcr file path"
    option :shortname, type: :string, required: true,
                      desc: "Machine-readable dataset ID"
    option :version, type: :string, required: true,
                    desc: "Semantic version (e.g. 1.0.0)"
    option :title, type: :string, desc: "Dataset title"
    option :description, type: :string, desc: "Dataset description"
    option :owner, type: :string, desc: "Dataset owner"
    option :register_yaml, type: :string,
                          desc: "Path to register.yaml to include in package"
    option :tags, type: :array, desc: "Tags for the dataset"
    def package(dir)
      require_relative "cli/package_command"
      Glossarist::CLI::PackageCommand.new(dir, options).run
    end

    desc "validate PATH", "Validate dataset directory or .gcr for schema compliance"
    option :strict, type: :boolean, default: false,
                   desc: "Treat warnings as errors"
    option :format, type: :string, default: "text",
                   enum: %w[text json yaml],
                   desc: "Output format for validation results"
    def validate(path)
      require_relative "cli/validate_command"
      Glossarist::CLI::ValidateCommand.new(path, options).run
    end

    def method_missing(*args)
      warn "No method found named: #{args[0]}"
      warn "Run with `--help` or `-h` to see available options"
      exit 1
    end

    def respond_to_missing?
      true
    end

    def self.exit_on_failure?
      true
    end

    private

    def output_latex(latex_str)
      output_file_path = options[:output_file]

      if output_file_path
        File.open(output_file_path, "w") { |file| file.puts latex_str }
      else
        puts latex_str
      end
    end
  end
end
