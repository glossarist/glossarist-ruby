# frozen_string_literal: true

module Glossarist
  # A reference to an item within a collection.
  #
  # Unifies bibliographic citations and concept references into a single
  # addressing model:
  #   collection  +  item  +  position within item
  #   source      +  id    +  locality
  #
  # Used by:
  #   ConceptSource#origin   — provenance reference to a document/element
  #   RelatedConcept#ref     — semantic reference to a concept in a termbase
  #   ManagedConceptData#domains — classification reference to a domain concept
  #   ConceptData#references — typed reference to a concept in a termbase
  #
  # YAML backward compatibility:
  #   - Reads both `id` and `concept_id` as the item identifier
  #   - Supports nested `ref: { source:, id: }` format (Citation legacy)
  #   - Supports flat `source:, concept_id:` format (ConceptReference legacy)
  class Reference < Lutaml::Model::Serializable
    # Collection identifier (document series, termbase, vocabulary)
    attribute :source, :string

    # Item identifier within the collection (document ID, concept ID)
    attribute :id, :string

    alias_method :concept_id, :id
    alias_method :concept_id=, :id=

    def initialize(attrs = {})
      if attrs.is_a?(Hash)
        attrs = attrs.dup
        attrs[:id] ||= attrs.delete(:concept_id) if attrs.key?(:concept_id)
      end
      super
    end

    # Version of the item or collection
    attribute :version, :string

    # Direct URL link
    attribute :link, :string

    # URN reference
    attribute :urn, :string

    # Position within the item
    attribute :locality, Locality

    # Unstructured text fallback
    attribute :text, :string

    # Pre-parsed original text
    attribute :original, :string

    # Internal: raw ref value for YAML serialization
    attribute :ref, :string

    # Custom locality entries
    attribute :custom_locality, CustomLocality, collection: true

    # Type qualifier (domain, local, urn, designation)
    attribute :ref_type, :string

    # Term text (used when referencing a concept)
    attribute :term, :string

    key_value do
      map %i[id concept_id], to: :id,
                             with: { from: :id_from_yaml, to: :id_to_yaml }
      map :source, to: :source,
                   with: { from: :source_from_yaml, to: :source_to_yaml }
      map :version, to: :version,
                    with: { from: :version_from_yaml, to: :version_to_yaml }
      map :text, to: :text,
                 with: { from: :text_from_yaml, to: :text_to_yaml }
      map :ref, to: :ref, with: { from: :ref_from_yaml, to: :ref_to_yaml }
      map %i[clause locality],
          to: :locality,
          with: { from: :locality_from_yaml, to: :locality_to_yaml }
      map :link, to: :link
      map :original, to: :original
      map %i[custom_locality customLocality], to: :custom_locality
      map :ref_type, to: :ref_type
      map :urn, to: :urn
      map :term, to: :term
    end

    # ── YAML serialization helpers ─────────────────────────────────────
    #
    # Two serialization modes:
    #   1. Concept-reference mode (flat): writes source, concept_id, urn, ref_type
    #      Used when ref_type or urn is set (domains, references, etc.)
    #   2. Citation mode (nested ref:): writes ref: { source:, id:, version: }
    #      Used for bibliographic citations in ConceptSource

    def concept_ref_mode?
      ref_type || urn
    end

    def id_from_yaml(model, value)
      model.id = value
    end

    def id_to_yaml(model, doc)
      doc["concept_id"] = model.id if model.id && model.concept_ref_mode?
    end

    def text_from_yaml(model, value)
      model.text = value
    end

    def text_to_yaml(_model, _doc)
      # handled in ref_to_yaml (citation mode)
    end

    def source_from_yaml(model, value)
      model.source = value
    end

    def source_to_yaml(model, doc)
      doc["source"] = model.source if model.source && model.concept_ref_mode?
    end

    def version_from_yaml(model, value)
      model.version = value
    end

    def version_to_yaml(_model, _doc)
      # handled in ref_to_yaml (citation mode)
    end

    def ref_from_yaml(model, value)
      if value.is_a?(Hash)
        model.source = value["source"]
        model.id = value["id"] || value["concept_id"]
        model.version = value["version"]
      else
        model.text = value
      end
    end

    def ref_to_yaml(model, doc)
      return if model.concept_ref_mode?

      doc["ref"] = if model.structured?
                     ref_hash(model)
                   else
                     model.text
                   end
    end

    def locality_from_yaml(model, value)
      locality = Locality.new

      if value.is_a?(Hash)
        locality.type = value["type"] || "clause"
        locality.reference_from = value["reference_from"] || value
        locality.reference_to = value["reference_to"] if value["reference_to"]
      else
        locality.type = "clause"
        locality.reference_from = value
      end
      locality.validate!
      model.locality = locality
    end

    def locality_to_yaml(model, doc)
      return unless model.locality

      doc["locality"] = {}
      doc["locality"]["type"] = model.locality.type
      doc["locality"]["reference_from"] = model.locality.reference_from if model.locality.reference_from
      doc["locality"]["reference_to"] = model.locality.reference_to if model.locality.reference_to
    end

    def ref_hash(model = self)
      { "source" => model.source, "id" => model.id, "version" => model.version }.compact
    end

    def ref=(ref)
      if ref.is_a?(Hash)
        @source = ref["source"]
        @id = ref["id"] || ref["concept_id"]
        @version = ref["version"]
      else
        @text = ref
      end
    end

    # ── Predicates ─────────────────────────────────────────────────────

    def plain?
      source.nil? && id.nil? && version.nil?
    end

    def structured?
      !plain?
    end

    def local?
      %w[local designation].include?(ref_type) ||
        (ref_type.nil? && (source.nil? || source.empty?))
    end

    def external?
      !local?
    end

    def dedup_key
      id ? [source, id] : [source, id, term]
    end

    # ── Convenience constructors ───────────────────────────────────────

    def self.domain(concept_id)
      new(id: concept_id, ref_type: "domain")
    end
  end
end
