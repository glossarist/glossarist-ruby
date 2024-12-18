module Glossarist
  class Concept < Lutaml::Model::Serializable
    attribute :id, :string
    attribute :uuid, :string
    attribute :designations, Designation::Base, collection: true
    attribute :domain, :string
    attribute :subject, :string
    attribute :definition, DetailedDefinition, collection: true
    attribute :non_verb_rep, :string
    attribute :notes, DetailedDefinition, default: -> { Glossarist::Collections::Collection.new(klass: DetailedDefinition) }, collection: true
    attribute :examples, DetailedDefinition, default: -> { Glossarist::Collections::Collection.new(klass: DetailedDefinition) }, collection: true
    attribute :extension_attributes, :string
    attribute :lineage_source, :string
    attribute :lineage_source_similarity, :integer
    attribute :release, :string
    attribute :sources, ConceptSource, default: -> { Glossarist::Collections::Collection.new(klass: ConceptSource) }, collection: true
    attribute :dates, ConceptDate, collection: true
    attribute :localizations, :hash
    attribute :extension_attributes, :hash
    attribute :related, RelatedConcept, collection: true
    attribute :data, :hash
    attribute :termid, :string
    attribute :authoritative_source, ConceptSource, collection: true
    attribute :terms, Designation::Base, collection: true

    alias :termid= :id=
    alias :identifier= :id=
    alias :terms :designations

    yaml do
      map :termid, to: :termid
      map :designations, to: :designations#, with: { to: :designations_to_hash, from: :designations_from_hash }
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
      map :related, to: :related#, with: { to: :related_to_hash, from: :related_from_hash }
      map :sources, to: :sources, with: { to: :sources_to_hash, from: :sources_from_hash }
      map :dates, to: :dates, with: { to: :dates_to_hash, from: :dates_from_hash }
      map :data, to: :data, with: { to: :data_to_hash, from: :data_from_hash }
      map :authoritative_source, to: :authoritative_source, with: { to: :auth_to_hash, from: :auth_from_hash }
      map :authoritativeSource, to: :authoritative_source, with: { to: :auth_to_hash, from: :auth_from_hash }
      map :terms, to: :terms, with: { to: :terms_to_hash, from: :terms_from_hash }

      map :date_accepted, with: { from: :date_accepted_from_yaml, to: :date_accepted_to_yaml }
      map :uuid, to: :uuid, with: { to: :uuid_to_hash, from: :uuid_from_hash }
      map :id, to: :id, with: { to: :id_to_hash, from: :id_from_hash }
      map :identifier, to: :id, with: { to: :id_to_hash, from: :id_from_hash }
    end

    def self.of_yaml(attrs, options = {})
      data = attrs.delete("data") || attrs.delete(:data)

      attrs.merge!(data) if data

      super(attrs, options)
    end

    def auth_to_hash(model, doc)
    end

    def auth_from_hash(model, value)
      model.authoritative_source = value if model.sources.empty?
    end

    def data_to_hash(model, doc)
      doc["data"] = data_hash(model)["data"]
      # doc.merge("id" => uuid)
    end

    def data_from_hash(model, value)
      model.data = value
    end

    def definition_to_hash(model, doc)

    end

    def definition_from_hash(model, value)
      model.definition = value
    end


    def data_hash(model)
      {
        "data" => {
          "dates" => model.dates&.map(&:to_yaml_hash),
          "definition" => model.definition.map(&:to_yaml_hash),
          "examples" => collection_helper(model.examples),
          "id" => model.id,
          "lineage_source_similarity" => model.lineage_source_similarity,
          "notes" => collection_helper(model.notes),
          "release" => model.release,
          "sources" => is_empty_array?(model.sources.map(&:to_yaml_hash)),
          "terms" => is_empty_array?(model.terms.map(&:to_yaml_hash)),
          "related" => is_empty_array?(model.related.map(&:to_yaml_hash)),
          "domain" => model.domain,
        }.compact
      }
    end

    def is_empty_array?(attr)
      attr.empty? ? nil : attr
    end

    def collection_helper(model)
      if model.is_a?(Glossarist::Collections::Collection)
        model.map(&:to_yaml_hash)
      else
        []
      end
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

    def terms_to_hash(model, doc)
    end

    def terms_from_hash(model, value)
      model.terms = value
    end

    def uuid_to_hash(model, doc)
      doc["id"] = model.uuid if model.uuid
    end

    def uuid_from_hash(model, value)
      model.uuid = value
    end

    def id_to_hash(model, doc)
    end

    def id_from_hash(model, value)
      model.id = value
    end

    def domain_to_hash(model, doc)
    end

    def domain_from_hash(model, value)
      model.domain = value
    end

    def notes_to_hash(model, doc)
    end

    def notes_from_hash(model, value)
      value.each do |v|
        model.notes << v
      end
    end

    def examples_to_hash(model, doc)
    end

    def examples_from_hash(model, value)
      value.each do |v|
        model.examples << v
      end
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

    def sources_to_hash(model, doc)
    end

    def sources_from_hash(model, value)
      model.sources = ConceptSource.of_yaml(value)
    end

    def dates_to_hash(model, doc)
    end

    def dates_from_hash(model, value)
      model.dates = value
    end

    def date_accepted_to_yaml(model, doc)
      doc["date_accepted"] = model.date_accepted.date.iso8601 if model.date_accepted
    end

    def date_accepted_from_yaml(model, value)
      return if model.date_accepted

      model.dates ||= []
      model.dates << ConceptDate.of_yaml({ "date" => value, "type" => "accepted" })
    end

    def uuid
      @uuid ||= Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE,
        data_hash(self).to_yaml,
      )
    end

    def authoritative_source=(sources)
      sources&.each do |source|
        @sources << source.merge({ "type" => "authoritative" })
      end
    end

    def authoritative_source
      @sources.select { |source| source.type == "authoritative" }
    end

    def related=(related)
      related = [related].compact unless related.is_a?(Array)
      @related = related.map do |r|
                   next r if r.is_a?(RelatedConcept)

                   RelatedConcept.of_yaml(r)
                 end
    end

    def dates=(dates)
      dates = [dates].compact unless dates.is_a?(Array)
      @dates = dates.map do |d|
                 next d if d.is_a?(ConceptDate)

                 ConceptDate.of_yaml(d)
               end
    end

    def definition=(definition)
      definition = [definition].compact unless definition.is_a?(Array)
      @definition = definition.map do |d|
                   next d if d.is_a?(DetailedDefinition)

                   DetailedDefinition.of_yaml(d)
                 end
    end

    def designations=(designations)
      designations = [designations].compact unless designations.is_a?(Array)
      @designations = designations.map do |d|
                   next d if d.is_a?(Designation::Base)

                   Designation::Base.of_yaml(d)
                 end
    end
    alias :terms= :designations=

    def id=(id)
      if !id.nil? && (id.is_a?(String) || id.is_a?(Integer))
        @id = id
      elsif !id.nil?
        raise(Glossarist::Error, "Expect id to be a String or Integer, Got #{id.class} (#{id})")
      end
    end

    def preferred_designations
      @designations.select(&:preferred?)
    end

    alias :preferred_terms :preferred_designations

    def date_accepted=(date)
      date_hash = {
        "type" => "accepted",
        "date" => date,
      }

      @dates ||= []
      @dates << ConceptDate.of_yaml(date_hash)
    end

    def date_accepted
      return nil unless @dates

      @dates.find { |date| date.accepted? }
    end
  end
end
