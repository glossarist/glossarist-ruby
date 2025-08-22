module Glossarist
  module Commands
    class GenerateLatex < Base
      def run
        assets = []
        latex_concepts_file = options[:latex_concepts]

        if options[:extra_attributes]
          Glossarist.configure do |config|
            config.register_extension_attributes(options[:extra_attributes])
          end
        end

        concept_set = Glossarist::ConceptSet.new(options[:concepts_path], assets)
        latex_str = concept_set.to_latex(latex_concepts_file)
        output_latex(latex_str)
      end

      def output_latex(latex_str)
        output_file_path = options[:output_file]

        if output_file_path
          File.open(output_file_path, "w") { |file| file.puts latex_str }
        else
          puts latex_str
        end
      end
    end
  end
end
