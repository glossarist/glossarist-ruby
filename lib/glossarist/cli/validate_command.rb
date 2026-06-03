# frozen_string_literal: true

require "paint"
require "table_tennis"

module Glossarist
  class CLI
    class ValidateCommand
      def initialize(path, options)
        @path = path
        @options = options
      end

      def run
        text_output = @options[:format] == "text"
        validator = DatasetValidator.new(on_progress: text_output ? method(:print_progress) : nil)
        result = validator.validate(
          @path,
          strict: @options[:strict],
          reference_path: @options[:reference_path],
        )

        $stderr.print "\r#{' ' * 60}\r" if text_output
        report(result)
        exit(1) unless result.errors.empty? && !strict_failure?(result)
      end

      private

      def strict_failure?(result)
        @options[:strict] && result.warnings.any?
      end

      def print_progress(current, total)
        pct = (current.to_f / total * 100).round
        bar_width = 30
        filled = (current.to_f / total * bar_width).round
        bar = "#{'█' * filled}#{'░' * (bar_width - filled)}"

        $stderr.print "\r  #{Paint['Validating',
                                   :bold]} #{bar} #{current}/#{total} (#{pct}%)"
        $stderr.flush
      end

      def report(result)
        case @options[:format]
        when "json"
          puts result.to_json
        when "yaml"
          puts result.to_yaml
        else
          print_text_output(result)
          print_table_output(result) if result.issues.any?
        end
      end

      def print_text_output(result)
        puts
        puts Paint["Validating #{@path}", :bold]
        puts

        if result.issues.empty?
          puts "  #{Paint['No issues found.', :green, :bold]}"
          return
        end

        print_grouped_issues(result)
        print_summary_line(result)
      end

      def print_grouped_issues(result)
        result.issues
          .group_by { |i| i.location || "(dataset)" }
          .sort_by { |loc, issues| [has_errors?(issues) ? 0 : 1, loc] }
          .each { |location, issues| print_location_group(location, issues) }
      end

      def has_errors?(issues)
        issues.any?(&:error?)
      end

      def print_location_group(location, issues)
        puts "  #{Paint[location, :cyan, :bold]}"
        issues.sort_by { |i| issue_sort_key(i) }
          .each { |issue| print_issue(issue) }
        puts
      end

      def issue_sort_key(issue)
        [issue.error? ? 0 : 1, issue.code || "￿", issue.message]
      end

      def print_issue(issue)
        color = issue.error? ? :red : :yellow
        label = Paint[issue.error? ? "ERROR" : " WARN", color, :bold]
        code = Paint["%-8s" % (issue.code || ""), :magenta]
        msg_col = 21

        puts "    #{label}  #{code}  #{issue.message}"
        if issue.suggestion
          puts "#{' ' * msg_col}#{Paint[issue.suggestion,
                                        :green]}"
        end
      end

      def print_summary_line(result)
        error_count = result.issues.count(&:error?)
        warning_count = result.issues.count(&:warning?)

        status = if error_count.positive?
                   Paint["INVALID", :red,
                         :bold]
                 else
                   Paint["VALID", :green,
                         :bold]
                 end

        details = []
        if error_count.positive?
          details << Paint["#{error_count} error(s)",
                           :red]
        end
        if warning_count.positive?
          details << Paint["#{warning_count} warning(s)",
                           :yellow]
        end

        puts "  #{status}  #{details.join(', ')}"
      end

      def print_table_output(result)
        rows = build_summary_rows(result)
        return if rows.empty?

        options = {
          title: "Issues by Rule",
          columns: %i[code severity count],
          headers: { code: "Rule", severity: "Level", count: "Count" },
          color_scales: { count: :gw },
          mark: ->(row) { row[:severity] == "error" },
          zebra: true,
        }
        puts
        puts TableTennis.new(rows, options)
      end

      def build_summary_rows(result)
        counts = Hash.new(0)
        severities = {}

        result.issues.each do |issue|
          key = issue.code || "unknown"
          counts[key] += 1
          severities[key] ||= issue.severity
        end

        counts.sort_by { |_, c| -c }.map do |code, count|
          { code: code, severity: severities[code], count: count }
        end
      end
    end
  end
end
