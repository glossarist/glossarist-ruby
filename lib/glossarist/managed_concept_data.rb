module Glossarist
  class ManagedConceptData < Lutaml::Model::Serializable
    include Glossarist::Utilities::CommonFunctions

    attribute :id, :string
    attribute :localized_concepts, :hash
    attribute :groups, :string, collection: true
    attribute :sources, ConceptSource, collection: true
    attribute :localizations, :hash, collection: true, default: -> { {} }

    yaml do
      map %i[id identifier], to: :id,
                             with: { to: :id_to_yaml, from: :id_from_yaml }
      map %i[localized_concepts localizedConcepts], to: :localized_concepts
      map :groups, to: :groups
      map :sources, to: :sources
      map :localizations, to: :localizations, with: { from: :localizations_from_yaml, to: :localizations_to_yaml }
    end

    def id_to_yaml(model, doc)
      value = model.id || model.identifier
      doc["identifier"] = value if value && !doc["identifier"]
    end

    def id_from_yaml(model, value)
      model.id = value unless model.id
    end

    def localizations_from_yaml(model, value)
      model.localizations ||= {}

      value.each do |localized_concept_hash|
        localized_concept = Glossarist::LocalizedConcept.of_yaml(localized_concept_hash)
        model.localizations[localized_concept.language_code] = localized_concept
      end
    end

    def localizations_to_yaml(model, doc)
    end

    def authoritative_source
      return [] unless sources

      sources.select { |source| source.authoritative? }
    end
  end
end
