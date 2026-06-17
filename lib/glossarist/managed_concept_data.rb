module Glossarist
  class ManagedConceptData < Lutaml::Model::Serializable
    include Glossarist::Utilities::CommonFunctions

    attribute :id, :string
    attribute :uri, :string
    attribute :localized_concepts, :hash
    attribute :domains, ConceptReference, collection: true
    attribute :tags, :string, collection: true
    attribute :figures, FigureReference, collection: true
    attribute :tables, TableReference, collection: true
    attribute :formulas, FormulaReference, collection: true
    attribute :sources, ConceptSource, collection: true
    attribute :localizations, LocalizedConcept,
              collection: Collections::LocalizationCollection,
              initialize_empty: true
    attribute :related, RelatedConcept, collection: true

    key_value do
      map %i[id identifier], to: :id,
                             with: { to: :id_to_yaml, from: :id_from_yaml }
      map :uri, to: :uri
      map %i[localized_concepts localizedConcepts], to: :localized_concepts
      map %i[domains groups], to: :domains,
                              with: { from: :domains_from_yaml, to: :domains_to_yaml }
      map :tags, to: :tags
      map :figures, to: :figures,
                    with: { from: :figures_from_yaml, to: :figures_to_yaml }
      map :tables, to: :tables,
                   with: { from: :tables_from_yaml, to: :tables_to_yaml }
      map :formulas, to: :formulas,
                     with: { from: :formulas_from_yaml, to: :formulas_to_yaml }
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

    def figures_from_yaml(model, value)
      model.figures = parse_non_verbal_refs(value, FigureReference)
    end

    def figures_to_yaml(model, doc)
      serialize_non_verbal_refs(model.figures, doc, "figures")
    end

    def tables_from_yaml(model, value)
      model.tables = parse_non_verbal_refs(value, TableReference)
    end

    def tables_to_yaml(model, doc)
      serialize_non_verbal_refs(model.tables, doc, "tables")
    end

    def formulas_from_yaml(model, value)
      model.formulas = parse_non_verbal_refs(value, FormulaReference)
    end

    def formulas_to_yaml(model, doc)
      serialize_non_verbal_refs(model.formulas, doc, "formulas")
    end

    private

    def parse_non_verbal_refs(value, ref_class)
      return unless value.is_a?(Array)

      value.map { |item| ref_class.of_yaml(item) }
    end

    def serialize_non_verbal_refs(refs, doc, key)
      return if refs.nil? || refs.empty?

      doc[key] = refs.map do |ref|
        ref.display ? { "ref" => ref.entity_id, "display" => ref.display } : ref.entity_id
      end
    end

    def authoritative_source
      return [] unless sources

      sources.select(&:authoritative?)
    end
  end
end
