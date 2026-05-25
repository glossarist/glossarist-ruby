# frozen_string_literal: true

require "paint"

module Glossarist
  class CLI
    class CompareCommand
      def initialize(new_path, old_path, options)
        @new_path = new_path
        @old_path = old_path
        @options = options
      end

      def run
        new_concepts = ConceptCollector.collect(@new_path)
        old_concepts = ConceptCollector.collect(@old_path)

        result = ConceptComparator.new(
          new_concepts: new_concepts,
          old_concepts: old_concepts,
        ).compare(show_diffs: !@options[:no_diffs])

        report(result)
      end

      private

      def report(result)
        case @options[:format]
        when "json"
          output result.to_json
        when "yaml"
          output result.to_yaml
        else
          print_text_report(result)
        end
      end

      def print_text_report(result)
        puts
        puts Paint["Concept Comparison", :bold]
        puts

        print_counts(result)
        print_new_only(result)
        print_old_only(result)
        print_similarity(result)

        puts
      end

      def print_counts(result)
        puts "  #{Paint['New:', :bold]} #{result.new_count} concepts"
        puts "  #{Paint['Old:', :bold]} #{result.old_count} concepts"
        puts "  #{Paint['Matched:', :bold]} #{result.matched.length}"
        puts "  #{Paint['New only:', :bold]} #{result.new_only.length}"
        puts "  #{Paint['Old only:', :bold]} #{result.old_only.length}"
      end

      def print_new_only(result)
        return unless result.new_only.any?

        puts
        puts "  #{Paint['New concepts (not in old):', :green, :bold]}"
        result.new_only.each { |id| puts "    + #{id}" }
      end

      def print_old_only(result)
        return unless result.old_only.any?

        puts
        puts "  #{Paint['Removed concepts (not in new):', :red, :bold]}"
        result.old_only.each { |id| puts "    - #{id}" }
      end

      def print_similarity(result)
        return unless result.diffs.any?

        puts
        puts "  #{Paint['Per-concept similarity:', :bold]}"
        result.diffs.each do |diff|
          color = similarity_color(diff.similarity)
          puts "    #{diff.concept_id}: #{Paint["#{diff.similarity}%", color]}"
        end
      end

      def similarity_color(value)
        if value >= 100
          :green
        elsif value >= 90
          :yellow
        else
          :red
        end
      end

      def output(content)
        if @options[:report]
          File.write(@options[:report], content)
        else
          puts content
        end
      end
    end
  end
end
