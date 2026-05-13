module Glossarist
  class ManagedConceptData < Lutaml::Model::Serializable
    include Glossarist::Utilities::CommonFunctions

    attribute :id, :string
    attribute :uri, :string
    attribute :localized_concepts, :hash
    attribute :domains, ConceptReference, collection: true
    attribute :sources, ConceptSource, collection: true
    attribute :localizations, LocalizedConcept,
              collection: Collections::LocalizationCollection,
              initialize_empty: true

    key_value do
      map %i[id identifier], to: :id,
                             with: { to: :id_to_yaml, from: :id_from_yaml }
      map :uri, to: :uri
      map %i[localized_concepts localizedConcepts], to: :localized_concepts
      map %i[domains groups], to: :domains,
                             with: { from: :domains_from_yaml, to: :domains_to_yaml }
      map :sources, to: :sources
      map :localizations, to: :localizations,
                          with: { from: :localizations_from_yaml, to: :localizations_to_yaml }
    end

    def id_to_yaml(model, doc)
      value = model.id
      doc["identifier"] = value if value && !doc["identifier"]
    end

    def id_from_yaml(model, value)
      model.id = value unless model.id
    end

    def localizations_from_yaml(model, value)
      value.each do |localized_concept_hash|
        localized_concept = Glossarist::LocalizedConcept.of_yaml(localized_concept_hash)
        model.localizations.store(localized_concept.language_code,
                                  localized_concept)
      end
    end

    def localizations_to_yaml(model, doc); end

    def domains_from_yaml(model, value)
      return unless value.is_a?(Array)

      model.domains = value.map do |item|
        if item.is_a?(Hash)
          ConceptReference.of_yaml(item)
        else
          ConceptReference.new(concept_id: item.to_s, ref_type: "domain")
        end
      end
    end

    def domains_to_yaml(model, doc)
      return if model.domains.nil? || model.domains.empty?

      doc["domains"] = model.domains.map(&:to_hash)
    end

    def authoritative_source
      return [] unless sources

      sources.select(&:authoritative?)
    end
  end
end
