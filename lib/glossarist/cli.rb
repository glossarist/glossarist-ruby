require "thor"
require "yaml"

require_relative "commands/base"
require_relative "commands/generate_latex"
require_relative "commands/compare_concepts"
require_relative "commands/validate_concepts"
require_relative "commands/validate_id_linkages"
require_relative "commands/version"

module Glossarist
  class Cli < Thor
    # Exit with error code on command failures
    def self.exit_on_failure?
      true
    end

    desc "generate_latex", "Convert Concepts to Latex format"
    method_option :concepts_path, aliases: :p, required: true,
                                  desc: "Path to yaml concepts directory"
    method_option :latex_concepts, aliases: :l,
                                   desc: "File path having list of concepts " \
                                         "that should be converted to " \
                                         "LATEX format. If not provided all " \
                                         "the concepts will be converted " \
                                         "to the latex format"
    method_option :output_file, aliases: :o,
                                desc: "Output file path. By default the " \
                                      "output will be printed to the console"

    method_option :extra_attributes, aliases: :e, type: :array,
                                     desc: "List of extra attributes that " \
                                           "are not in standard Glossarist " \
                                           "Concept model"
    def generate_latex
      Commands::GenerateLatex.new(options).run
    end

    desc "compare_concepts", "Compare New Concepts (Concepts and their " \
         "localized concepts are stored in the same YAML Stream file) with " \
         "Old Concepts (Concepts and their localized concepts are stored in " \
         "different YAML files)"
    method_option :new_concept_path, aliases: :n, required: true,
                                     desc: "Path to new yaml concepts directory"
    method_option :old_concept_path, aliases: :o, required: true,
                                     desc: "Path to old yaml concepts directory"
    method_option :report_path, aliases: :r,
                                desc: "Path to report file"
    method_option :color, aliases: :c, type: :boolean, default: false,
                          desc: "Colorize differences"
    def compare_concepts
      Commands::CompareConcepts.new(options).run
    end

    desc "validate_id_linkages", "Validate ID linkages in Concept YAML"
    method_option :concept_path, aliases: :p, required: true,
                                 desc: "Path to yaml concepts directory"
    method_option :report_path, aliases: :r,
                                desc: "Path to report file"
    def validate_id_linkages
      Commands::ValidateIdLinkages.new(options).run
    end

    desc "validate_concepts", "Validate Concept models"
    method_option :concept_path, aliases: :p, required: true,
                                 desc: "Path to yaml concepts directory"
    method_option :report_path, aliases: :r,
                                desc: "Path to report file"
    def validate_concepts
      Commands::VerifyConcepts.new(options).run
    end

    desc "version", "Print Glossarist Version"
    def version
      Commands::Version.new(options).run
    end
  end
end
