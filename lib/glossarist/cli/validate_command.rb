# frozen_string_literal: true

module Glossarist
  class CLI
    class ValidateCommand
      def initialize(path, options)
        @path = path
        @options = options
      end

      def run
        result = DatasetValidator.new.validate(
          @path,
          strict: @options[:strict],
          reference_path: @options[:reference_path],
        )
        report(result)
        exit_code = result.errors.any? || (@options[:strict] && result.warnings.any?) ? 1 : 0
        exit(exit_code) unless exit_code.zero?
      end

      private

      def report(result)
        case @options[:format]
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

        if result.warnings.any?
          result.warnings.each do |w|
            puts "  WARNING: #{w}"
          end
        end

        total = result.errors.length + result.warnings.length
        puts "#{total} issue(s) found."
      end
    end
  end
end
