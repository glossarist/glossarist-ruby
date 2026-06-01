# frozen_string_literal: true

require "lutaml/store"

module Glossarist
  class ConceptStore
    # Custom serializer that preserves both uuid and identifier through
    # YAML string storage. ManagedConcept's key_value mapping writes both
    # uuid and identifier to the same "id" key, so a naive to_hash/from_hash
    # round-trip loses one of them. Storing the YAML string preserves the
    # model exactly, and explicit metadata fields let the store index and
    # query by uuid/identifier without deserializing.
    class Serializer
      def serialize(model)
        {
          "_yaml" => model.to_yaml,
          "_uuid" => model.uuid,
          "_identifier" => model.identifier,
        }
      end

      def deserialize(data, model_class)
        model = model_class.from_yaml(data["_yaml"])
        model.assign_uuid(data["_uuid"]) if data["_uuid"]
        model.identifier = data["_identifier"] if data["_identifier"]
        model
      end
    end

    attr_reader :db

    def initialize(adapter: :memory)
      @db = Lutaml::Store::DatabaseStore.new(
        adapter: adapter,
        models: [managed_concept_registration],
      )
    end

    def save(concept)
      db.save(concept)
    end

    def fetch(uuid)
      db.fetch(model: ManagedConcept, uuid: uuid)
    end

    def fetch_by_id(identifier)
      db.where(model: ManagedConcept, identifier: identifier).first
    end

    def update(uuid, **attributes)
      db.update(model: ManagedConcept, uuid: uuid, attributes: attributes)
    end

    def delete(uuid)
      db.destroy(model: ManagedConcept, uuid: uuid)
    end

    def all
      db.all(model: ManagedConcept)
    end

    def count
      db.count(model: ManagedConcept)
    end

    def exists?(uuid)
      db.exists?(model: ManagedConcept, uuid: uuid)
    end

    def clear
      all.each { |concept| delete(concept.uuid) }
    end

    def load_from_directory(path, format: :yaml, layout: :separate)
      db.import_all(ManagedConcept, path: path, format: format, layout: layout)
    end

    def save_to_directory(path, format: :yaml, layout: :separate)
      db.save_all(all, path: path, format: format, layout: layout)
    end

    private

    def managed_concept_registration
      {
        model: ManagedConcept,
        key: :uuid,
        dir: "concept",
        serializer: Serializer.new,
      }
    end
  end
end
