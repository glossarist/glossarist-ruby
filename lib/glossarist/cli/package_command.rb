# frozen_string_literal: true

module Glossarist
  class CLI
    class PackageCommand
      def initialize(dir, options)
        @dir = dir
        @options = options
      end

      def run
        GcrPackage.create_from_directory(
          @dir,
          output: @options[:output],
          shortname: @options[:shortname],
          version: @options[:version],
          title: @options[:title],
          description: @options[:description],
          owner: @options[:owner],
          tags: @options[:tags],
          register_yaml: @options[:register_yaml],
          uri_prefix: @options[:uri_prefix],
        )

        puts "Created #{@options[:output]}"
      rescue ArgumentError => e
        warn "Error: #{e.message}"
        exit 1
      end
    end
  end
end
