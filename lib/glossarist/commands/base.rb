module Glossarist
  module Commands
    class Base
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      # Common utilities that all commands might need
      def say(message)
        # Use instance variable for testability - if output is set, use it
        if defined?(@output) && @output
          @output.puts(message)
        else
          puts(message)
        end
      end

      def exit_with_error(message, exit_code = 1)
        say message
        # In test mode, raise an exception instead of exiting
        # This makes it easier to test error cases
        if defined?(@test_mode) && @test_mode
          raise message # Just raise the message as an exception
        else
          exit exit_code
        end
      end

      def load_concepts(dataset_concept_path)
        collection = Glossarist::ManagedConceptCollection.new
        collection.load_from_files(dataset_concept_path)
        collection
      end

      def output(content)
        # add a newline at the end of the content
        content << ""

        # output on screen
        puts content

        use_color_codes = options[:color]
        report_path = options[:report_path] || "report.txt"

        File.open(report_path, "w") do |file|
          file.write(
            content.map do |line|
              if use_color_codes
                line.to_s
              else
                # remove color codes
                line.to_s.gsub(/\e\[\d+m/, "")
              end
            end.join("\n"),
          )
        end
      end

      def relative_path(to, from = nil)
        gem_root = Gem::Specification.find_by_name("glossarist").gem_dir
        from = gem_root if from.nil?
        Pathname.new(to).relative_path_from(Pathname.new(from)).to_s
      end
    end
  end
end
