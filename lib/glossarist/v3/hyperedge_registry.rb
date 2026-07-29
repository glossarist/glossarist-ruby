# frozen_string_literal: true

module Glossarist
  module V3
    # HyperedgeRegistry — single SSOT for hyperedge-class lookup by
    # every external identifier (wire key, type tag, RDF type).
    #
    # Auto-populates on class inheritance via AbstractHyperedge.inherited.
    # Concrete leaves declare WIRE_KEY / TYPE_TAG / RDF_TYPE constants
    # in a per-class metadata block; the registry reads them once at
    # registration time.
    #
    # Adding a new hyperedge type means declaring one leaf class with
    # the metadata block. No edit to any other file (parser, serializer,
    # validator, RDF emitter, RelationLoader) — they all iterate or
    # resolve through this registry.
    module HyperedgeRegistry
      # Mutable: register adds entries at load time. DO NOT freeze.
      BY_WIRE_KEY = {}
      BY_TYPE_TAG = {}
      BY_RDF_TYPE = {}

      Mutex = ::Mutex.new

      class << self
        # Register a concrete hyperedge class. Idempotent.
        def register(cls)
          return if cls.nil? || cls.const_defined?(:WIRE_KEY) == false

          Mutex.synchronize do
            wire = cls::WIRE_KEY
            tag  = cls::TYPE_TAG
            rdf  = cls::RDF_TYPE

            BY_WIRE_KEY[wire] = cls unless wire.nil? || wire.empty?
            BY_TYPE_TAG[tag]  = cls unless tag.nil? || tag.empty?
            BY_RDF_TYPE[rdf]  = cls unless rdf.nil? || rdf.empty?
          end
        end

        # Iterate every concrete leaf (use this in parser / serializer
        # / loader to stay type-blind).
        def all_classes
          BY_TYPE_TAG.values.uniq
        end

        def for_wire_key(key)
          BY_WIRE_KEY[key]
        end

        def for_type_tag(tag)
          BY_TYPE_TAG[tag]
        end

        def for_rdf_type(rdf_type)
          BY_RDF_TYPE[rdf_type]
        end

        # Reset (spec helper — never call from production code).
        def reset!
          Mutex.synchronize do
            BY_WIRE_KEY.clear
            BY_TYPE_TAG.clear
            BY_RDF_TYPE.clear
          end
        end
      end
    end
  end
end
