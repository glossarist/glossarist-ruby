# frozen_string_literal: true

module Glossarist
  class CLI
    class ImportCommand
      def initialize(files, options)
        @files = files
        @options = options
      end

      def run
        importer = Sts::Importer.new(
          duplicate_strategy: @options[:on_duplicate]&.to_sym || :skip,
        )

        result = if @options[:into]
                   importer.import_into_existing(@files, @options[:into])
                 else
                   importer.import_new(@files, **import_new_args)
                 end

        print_summary(result)
      rescue ArgumentError => e
        warn "Error: #{e.message}"
        exit 1
      end

      private

      def import_new_args
        {
          output: @options[:output],
          shortname: @options[:shortname],
          version: @options[:version],
          title: @options[:title],
          description: @options[:description],
          owner: @options[:owner],
          uri_prefix: @options[:uri_prefix],
        }
      end

      def print_summary(result) # rubocop:disable Metrics/AbcSize
        dest = @options[:into] || @options[:output]
        puts "Imported #{result.concepts.length} concepts to #{dest}"
        puts "  Source files: #{@files.join(', ')}" if @files.any?
        return unless result.conflict?

        puts "  #{result.conflicts.length} duplicate(s) detected " \
             "(strategy: #{@options[:on_duplicate] || 'skip'})"
        puts "  #{result.skipped_count} concept(s) skipped" if result.skipped_count.positive?
      end
    end
  end
end
