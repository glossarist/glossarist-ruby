module Glossarist
  module LutamlModel
    class ConceptSet < Lutaml::Model::Serializable
      attribute :bibliographies, :string
      attribute :assets, :string
      attribute :options, :hash

      yaml do
        map :bibliographies, to: :bibliographies
        map :assets, to: :assets
        map :options, to: :options
      end

      def to_latex(filename = nil)
        return to_latex_from_file(filename) if filename

        @concepts.map do |concept|
          latex_template(concept)
        end.join("\n")
      end

      def read_concepts(concepts)
        return concepts if concepts.is_a?(Glossarist::LutamlModel::ManagedConceptCollection)

        collection = Glossarist::LutamlModel::ManagedConceptCollection.new
        collection.load_from_files(concepts)
        collection
      end

      def latex_template(concept)
        <<~TEMPLATE
          \\newglossaryentry{#{concept.default_designation.gsub('_', '-')}}
          {
          name={#{concept.default_designation.gsub('_', '\_')}}
          description={#{normalize_definition(concept.default_definition)}}
          }
        TEMPLATE
      end

      def normalize_definition(definition)
        definition.gsub(/{{([^}]*)}}/) do |match|
          "\\textbf{\\gls{#{Regexp.last_match[1].gsub('_', '-')}}}"
        end
      end

      def concept_map
        @concept_map ||= concepts.managed_concepts.map do |concept|
          [concept.default_designation.downcase, concept]
        end.to_h
      end
    end
  end
end
