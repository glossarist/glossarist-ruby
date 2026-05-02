# frozen_string_literal: true

module Glossarist
  class CLI
    class UpgradeCommand
      def initialize(source_dir, options)
        @source_dir = source_dir
        @options = options
      end

      def run
        result = SchemaMigration.upgrade_directory(
          @source_dir,
          output: @options[:output],
          target_version: @options[:target_version],
          cross_references: @options[:cross_references],
          dry_run: @options[:dry_run],
        )
        report(result)
      rescue ArgumentError => e
        warn "Error: #{e.message}"
        exit 1
      end

      private

      def report(result)
        puts "Upgraded #{result[:count]} concepts " \
             "from schema v#{result[:source_version]} to v#{result[:target_version]}"
        puts "Output: #{result[:output]}"
      end
    end
  end
end
