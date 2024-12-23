module Glossarist
  class Concept < Lutaml::Model::Serializable
    attribute :data, ConceptData, default: -> { ConceptData.new }
    attribute :id, :string
    attribute :uuid, :string
    attribute :subject, :string
    attribute :non_verb_rep, :string
    attribute :extension_attributes, :string
    attribute :lineage_source, :string
    attribute :localizations, :hash
    attribute :extension_attributes, :hash
    attribute :termid, :string

    yaml do
      map :data, to: :data
      map :termid, to: :termid
      map :subject, to: :subject
      map :non_verb_rep, to: :non_verb_rep
      map :extension_attributes, to: :extension_attributes
      map :lineage_source, to: :lineage_source
      map :localizations, to: :localizations
      map :extension_attributes, to: :extension_attributes

      map :date_accepted, with: { from: :date_accepted_from_yaml, to: :date_accepted_to_yaml }
      map :uuid, to: :uuid, with: { to: :uuid_to_yaml, from: :uuid_from_yaml }
      map :id, to: :id, with: { to: :id_to_yaml, from: :id_from_yaml }
      map :identifier, to: :id, with: { to: :id_to_yaml, from: :id_from_yaml }
    end

    def designations
      data.terms
    end
    alias :terms :designations

    def definition
      data.definition
    end

    def definition=(value)
      data.definition = value
    end

    def sources
      data.sources
    end

    def examples
      data.examples
    end

    def notes
      data.notes
    end

    def preferred_designations
      data.terms.select(&:preferred?)
    end
    alias :preferred_terms :preferred_designations

    def date_accepted
      data.date_accepted
    end

    def authoritative_source
      data.authoritative_source
    end

    def uuid_to_yaml(model, doc)
      doc["id"] = model.uuid if model.uuid
    end

    def uuid_from_yaml(model, value)
      model.uuid = value
    end

    def id_to_yaml(model, doc)
    end

    def id_from_yaml(model, value)
      model.id = value
    end

    def date_accepted_to_yaml(model, doc)
      doc["date_accepted"] = model.date_accepted.date.iso8601 if model.date_accepted
    end

    def date_accepted_from_yaml(model, value)
      return if model.date_accepted

      model.data.dates ||= []
      model.data.dates << ConceptDate.of_yaml({ "date" => value, "type" => "accepted" })
    end

    def uuid
      @uuid ||= Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE,
        data.to_yaml,
      )
    end
  end
end
