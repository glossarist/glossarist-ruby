module Glossarist
  module LutamlModel
    class Concept < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :uuid, :string
      attribute :designations, :string
      attribute :domain, :string
      attribute :subject, :string
      attribute :definition, DetailedDefinition
      attribute :non_verb_rep, :string
      attribute :notes, DetailedDefinition
      attribute :examples, DetailedDefinition
      attribute :extension_attributes, :string
      attribute :lineage_source, :string
      attribute :lineage_source_similarity, :string
      attribute :release, :string
      attribute :sources, ConceptSource
      attribute :dates, ConceptDate, collection: true
      attribute :localizations, :hash
      attribute :extension_attributes, :hash
      attribute :related, RelatedConcept

      alias :termid= :id=
      alias :identifier= :id=
      alias :terms= :designations=

      yaml do
        map :id, to: :id
        map :uuid, to: :uuid
        map :designations, to: :designations
        map :domain, to: :domain
        map :subject, to: :subject
        map :definition, to: :definition
        map :non_verb_rep, to: :non_verb_rep
        map :notes, to: :notes
        map :examples, to: :examples
        map :extension_attributes, to: :extension_attributes
        map :lineage_source, to: :lineage_source
        map :lineage_source_similarity, to: :lineage_source_similarity
        map :release, to: :release
        map :localizations, to: :localizations
        map :extension_attributes, to: :extension_attributes
        map :related, to: :related
        map :sources, to: :sources
        map :dates, to: :dates
      end

      def id=(id)
        # Some of the glossaries that are not generated using glossarist, contains ids that are integers
        # so adding a temporary check until every glossary is updated using glossarist.
        if !id.nil? && (id.is_a?(String) || id.is_a?(Integer))
          @id = id
        else
          raise(Glossarist::Error, "Expect id to be a String or Integer, Got #{id.class} (#{id})")
        end
      end

      def examples=(examples)
        @examples.clear!
        examples&.each { |example| @examples << example }
      end
  
      def notes=(notes)
        @notes.clear!
        notes&.each { |note| @notes << note }
      end
  
      def definition=(definition)
        @definition.clear!
        definition&.each { |definition| @definition << definition }
      end
  
      def designations=(designations)
        @designations.clear!
        designations&.each { |designation| @designations << designation }
      end

      def dates=(dates)
        @dates.clear!
        dates&.each { |date| @dates << date }
      end
  
      def sources=(sources)
        @sources.clear!
        sources&.each { |source| @sources << source }
      end

      def authoritative_source=(sources)
        sources&.each do |source|
          @sources << source.merge({ "type" => "authoritative" })
        end
      end

      def date_accepted=(date)
        date_hash = {
          "type" => "accepted",
          "date" => date,
        }
  
        @dates ||= []
        @dates << ConceptDate.new(date_hash)
      end

      def related=(related)
        @related.clear!
        related&.each { |r| @related << r }
      end
    end
  end
end
