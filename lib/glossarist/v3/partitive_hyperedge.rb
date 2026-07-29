# frozen_string_literal: true

module Glossarist
  module V3
    # PartitiveHyperedge — an ISO 704 / ISO 1087-1 / ISO 12620 partitive
    # hyperedge connecting a comprehensive concept (superordinate concept
    # partitive) to two or more partitive concepts (subordinate concepts
    # partitive) which fitted together constitute the comprehensive.
    #
    # Inherits structure and validations from AbstractHyperedge.
    # The `comprehensive` field denotes the whole concept.
    #
    # Per-file storage: lives at
    # relations/<comprehensive-id>/<criterion-slug>.yaml — see
    # docs/design/relations-as-files.md (concept-model repo).
    #
    # The `key_value` mapping is inherited from AbstractHyperedge
    # (single SSOT). Only the typed member collection is narrowed here.
    #
    # Per-class metadata block — the SSOT for this leaf's external
    # identifiers. Adding a new hyperedge type means declaring a new
    # class with an equivalent block; no other file needs editing
    # (parsers, serializers, validators, RDF emitters, and the loader
    # all dispatch through HyperedgeRegistry by these constants).
    class PartitiveHyperedge < AbstractHyperedge
      # YAML key on Concept (legacy bundled-format wire name; kept for
      # backward compat with concept-model).
      WIRE_KEY = "partitive_relations"

      # Per-file `type:` discriminator in relations/<id>/<slug>.yaml.
      TYPE_TAG = "partitive_relation"

      # RDF type URI (gloss: ontology — concept-model contract).
      RDF_TYPE = "gloss:PartitiveRelation"

      # Member class — narrows the parent's members: HyperedgeMember.
      MEMBER_CLASS = PartitiveMember

      # Legacy v1 wire keys that migrate to this class on parse.
      V1_WIRE_KEYS = %w[partitive_hyperedges].freeze

      # Short label for diff display ("PART" / "GEN" / etc.).
      KIND_LABEL = "PART"

      attribute :members, PartitiveMember, collection: true
    end

    # Auto-register with HyperedgeRegistry. Adding a new hyperedge
    # type means adding a class with an equivalent block + this one
    # register call — nothing else in the codebase changes.
    HyperedgeRegistry.register(PartitiveHyperedge)
  end
end
