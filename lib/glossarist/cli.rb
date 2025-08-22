require "thor"
require "yaml"
require "terminal-table"

require_relative "commands/base"
require_relative "commands/generate_latex"
require_relative "commands/version"

module Glossarist
  class Cli < Thor
    # Exit with error code on command failures
    def self.exit_on_failure?
      true
    end

    desc "generate_latex", "Convert Concepts to Latex format"
    method_option :concepts_path,
    aliases: :p,
    required: true,
    desc: "Path to yaml concepts directory"
    method_option :latex_concepts,
    aliases: :l,
    desc: "File path having list of concepts that should be converted to " \
          "LATEX format. If not provided all the concepts will be converted " \
          "to the latex format"
    method_option :output_file,
    aliases: :o,
    desc: "Output file path. By default the output will be printed to the " \
          "console"
    method_option :extra_attributes,
    aliases: :e,
    type: :array,
    desc: "List of extra attributes that are not in standard Glossarist " \
          "Concept model"
    def generate_latex
      Commands::GenerateLatex.new(options).run
    end

    desc "version", "Glossarist Version"
    def version
      Commands::Version.new(options).run
    end
  end
end
