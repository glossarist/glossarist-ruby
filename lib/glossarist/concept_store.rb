# frozen_string_literal: true

module Glossarist
  class ConceptStore
    # Serializes ConceptDocument for storage in lutaml-store.
    # Stores the YAML stream string to preserve the full concept + localizations.
    class ConceptDocumentSerializer
      def serialize(concept_document)
        {
          "_yamls" => concept_document.to_yamls,
          "_id" => concept_document.id,
        }
      end

      def deserialize(data, model_class)
        doc = model_class.from_yamls(data["_yamls"])
        doc.id = data["_id"]
        concept = doc.concept
        # doc.id from the store is the record key, which for the grouped
        # layout is the filename stem. The filename may differ from the
        # concept's UUID when datasets name files by clause identifier
        # (e.g. `3.1.1.1.yaml`) rather than by UUID. Only propagate
        # doc.id to concept.uuid when the YAML stream did not already
        # provide one — the YAML is the source of truth.
        if doc.id && concept && concept.uuid.nil?
          concept.uuid = doc.id
        end
        doc.localizations.each { |l10n| concept&.add_localization(l10n) }
        doc
      end
    end

    attr_reader :db

    def initialize(adapter: :memory)
      @db = Lutaml::Store::DatabaseStore.new(
        adapter: adapter,
        models: [concept_document_registration],
      )
    end

    def load_glossary(path)
      documents = db.load_all(
        V3::ConceptDocument, path: path, format: :yamls, layout: :grouped
      )

      documents.each do |doc|
        concept = doc.concept
        # See ConceptDocumentSerializer#deserialize: only fall back to the
        # filename-derived doc.id when the YAML stream has no UUID.
        concept.uuid ||= doc.id
        db.save(doc)
      end

      documents
    end

    def fetch(uuid)
      doc = db.fetch(model: V3::ConceptDocument, id: uuid)
      doc&.concept
    end

    def concepts
      db.all(model: V3::ConceptDocument).map(&:concept)
    end

    def count
      db.count(model: V3::ConceptDocument)
    end

    def exists?(uuid)
      db.exists?(model: V3::ConceptDocument, id: uuid)
    end

    def clear
      db.all(model: V3::ConceptDocument).each do |doc|
        db.destroy(model: V3::ConceptDocument, id: doc.id)
      end
    end

    private

    def concept_document_registration
      {
        model: V3::ConceptDocument,
        key: :id,
        dir: "concepts",
        serializer: ConceptDocumentSerializer.new,
      }
    end
  end
end
