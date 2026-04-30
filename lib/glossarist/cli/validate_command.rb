# frozen_string_literal: true

module Glossarist
  class CLI
    class ValidateCommand
      def initialize(path, options)
        @path = path
        @strict = options[:strict]
        @format = options[:format]
      end

      def run
        result = validate_path
        report(result)
        exit_code = result.errors.any? || (@strict && result.warnings.any?) ? 1 : 0
        exit(exit_code) unless exit_code.zero?
      end

      private

      def validate_path
        if File.extname(@path).downcase == ".gcr"
          validate_gcr
        else
          validate_directory
        end
      end

      def validate_gcr
        require "glossarist/gcr_package"
        package = GcrPackage.new(@path)
        package.validate
      end

      def validate_directory
        validator = ConceptValidator.new(@path)
        validator.validate_all
      end

      def report(result)
        case @format
        when "json"
          require "json"
          puts JSON.pretty_generate(result.to_h)
        when "yaml"
          require "yaml"
          puts YAML.dump(result.to_h)
        else
          report_text(result)
        end
      end

      def report_text(result)
        if result.valid?
          puts "Valid."
        else
          puts "Invalid."
          result.errors.each { |e| puts "  ERROR: #{e}" }
        end

        result.warnings.each { |w| puts "  WARNING: #{w}" } if result.warnings.any?

        total = result.errors.length + result.warnings.length
        puts "#{total} issue(s) found."
      end
    end
  end
end
