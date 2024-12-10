module Glossarist
  module LutamlModel
    class Concept < Lutaml::Model::Serializable
      attribute :id, :string
      attribute :uuid, :string
      attribute :designations, :string
      attribute :domain, :string
      attribute :subject, :string
      attribute :definition, DetailedDefinition, collection: true
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
      attribute :data, :hash
      attribute :preferred_designations, :string
      attribute :date_accepted, :string
      attribute :termid, :string

      alias :termid= :id=
      alias :identifier= :id=
      alias :terms= :designations=
      alias :terms :designations
      alias :preferred_terms :preferred_designations

      yaml do
        map :termid, to: :termid
        map :id, to: :id, with: { to: :id_to_hash, from: :id_from_hash }
        map :uuid, to: :uuid
        map :designations, to: :designations, with: { to: :designations_to_hash, from: :designations_from_hash }
        map :domain, to: :domain, with: { to: :domain_to_hash, from: :domain_from_hash }
        map :subject, to: :subject
        map :definition, to: :definition, with: { to: :definition_to_hash, from: :definition_from_hash }
        map :non_verb_rep, to: :non_verb_rep
        map :notes, to: :notes, with: { to: :notes_to_hash, from: :notes_from_hash }
        map :examples, to: :examples, with: { to: :examples_to_hash, from: :examples_from_hash }
        map :extension_attributes, to: :extension_attributes
        map :lineage_source, to: :lineage_source
        map :lineage_source_similarity, to: :lineage_source_similarity, with: { to: :lss_to_hash, from: :lss_from_hash }
        map :release, to: :release, with: { to: :release_to_hash, from: :release_from_hash }
        map :localizations, to: :localizations
        map :extension_attributes, to: :extension_attributes
        map :related, to: :related, with: { to: :related_to_hash, from: :related_from_hash }
        map :sources, to: :sources, with: { to: :sources_to_hash, from: :sources_from_hash }
        map :dates, to: :dates, with: { to: :dates_to_hash, from: :dates_from_hash }
        map :date_accepted, to: :date_accepted, with: { to: :date_accepted_to_hash, from: :date_accepted_from_hash }
        map :preferred_designations, to: :preferred_designations
        map :data, to: :data, with: { to: :data_to_hash, from: :data_from_hash }
      end

      def data_to_hash(model, doc)
        doc["data"] = data_hash(model)
        doc.merge("date_accepted" => model.date_accepted,
                  "id" => uuid)
      end

      def data_from_hash(model, value)
        model.data = value
      end

      def data_hash(model)
        {
          "dates" => model.dates.empty? ? nil : model.dates,
          "definition" => model.definition,
          "examples" => model.examples,
          "id" => model.id,
          "lineage_source_similarity" => model.lineage_source_similarity,
          "notes" => model.notes,
          "release" => model.release,
          "sources" => model.sources,
          "terms" => model.terms,
          "related" => model.related_helper,
          "domain" => model.domain,
        }.compact
      end

      def related_helper
        related&.map do |related|
          {
            "content" => related.content,
            "type" => related.type,
            "ref" => related.ref
          }.compact
        end
      end

      def id_to_hash(model, doc)
      end

      def id_from_hash(model, value)
        model.id = value
      end

      def designations_to_hash(model, doc)
      end

      def designations_from_hash(model, value)
        model.designations = value
      end

      def domain_to_hash(model, doc)
      end

      def domain_from_hash(model, value)
        model.domain = value
      end

      def definition_to_hash(model, doc)
      end

      def definition_from_hash(model, value)
        model.definition = value
      end

      def notes_to_hash(model, doc)
      end

      def notes_from_hash(model, value)
        model.notes = value
      end

      def examples_to_hash(model, doc)
      end

      def examples_from_hash(model, value)
        model.examples = value
      end

      def lss_to_hash(model, doc)
      end

      def lss_from_hash(model, value)
        model.lineage_source_similarity = value
      end

      def release_to_hash(model, doc)
      end

      def release_from_hash(model, value)
        model.release = value
      end

      def related_to_hash(model, doc)
      end

      def related_from_hash(model, value)
      end

      def sources_to_hash(model, doc)
      end

      def sources_from_hash(model, value)
        model.sources = value
      end

      def dates_to_hash(model, doc)
      end

      def dates_from_hash(model, value)
        model.dates = value
      end

      def date_accepted_to_hash(model, doc)
      end

      def date_accepted_from_hash(model, value)
        model.date_accepted = value
      end

      def uuid
        @uuid ||= Glossarist::Utilities::UUID.uuid_v5(
          Glossarist::Utilities::UUID::OID_NAMESPACE,
          {"data" => data_hash(self)}.to_yaml,
        )
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
  
      # def sources=(sources)
      #   @sources.clear!
      #   sources&.each { |source| @sources << source }
      # end

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

      # def related=(related)
      #   binding.irb
      #   t = self.class.to_yaml(related)
      #   attribute.type.new(related)
      #   # related&.each { |r| RelatedConcept.new(r) }
      # end
    end
  end
end
