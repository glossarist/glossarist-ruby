# frozen_string_literal: true

require "yaml"
require "fileutils"
require "pathname"

module Glossarist
  module V3
    # HyperedgeWriter — the WRITE half of per-file hyperedge storage.
    #
    # Mirror of RelationLoader. Each hyperedge is serialized to
    # `relations/<comprehensive-id>/<criterion-slug>.yaml` with the
    # full per-file wire format ($id, type, comprehensive, members,
    # criterion, sources, notes, status, completeness).
    #
    # Per-file storage means a single concept (e.g., OIML 5.1
    # measurement standard) can have N hyperedges (one per criterion),
    # each in its own file under relations/<comp-id>/.
    class HyperedgeWriter
      class WriteError < ::StandardError
      end

      class << self
        # Write a single hyperedge to its per-file location under
        # `relations_dir`. Creates the comprehensive-id subdirectory
        # if missing. Returns the absolute path written.
        def write(hyperedge, relations_dir)
          new(relations_dir).write(hyperedge)
        end

        # Write a batch of hyperedges. Returns an Array<String> of
        # paths written. Hyperedges with the same comprehensive are
        # written to the same subdirectory.
        def write_all(hyperedges, relations_dir)
          new(relations_dir).write_all(hyperedges)
        end
      end

      def initialize(relations_dir)
        @relations_dir = Pathname.new(relations_dir)
      end

      def write(hyperedge)
        raise WriteError, "not an AbstractHyperedge: #{hyperedge.class}" unless
          hyperedge.is_a?(AbstractHyperedge)

        path = hyperedge.file_path(@relations_dir)
        unless path
          raise WriteError,
                "cannot derive file path — comprehensive must be non-empty"
        end

        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, serialize(hyperedge))
        path
      end

      def write_all(hyperedges)
        Array(hyperedges).map { |h| write(h) }
      end

      private

      # Serialize with stable key ordering: $id, type, status,
      # comprehensive, members, completeness, criterion, sources,
      # notes. Matches the concept-model per-file format.
      def serialize(hyperedge)
        hash = hyperedge.to_hash
        hash["$id"] = hyperedge.file_id || hyperedge.derived_file_id
        hash["type"] = hyperedge.class::TYPE_TAG
        strip_falsey_concept_ref_flags!(hash)
        ordered = {}
        ordered["$id"]         = hash.delete("$id")
        ordered["type"]        = hash.delete("type")
        ordered["status"]      = hash.delete("status") if hash.key?("status")
        ordered["comprehensive"] = hash.delete("comprehensive")
        ordered["members"] = hash.delete("members")
        ordered["completeness"] = hash.delete("completeness") if hash.key?("completeness")
        ordered["criterion"]   = hash.delete("criterion") if hash.key?("criterion")
        ordered["sources"]     = hash.delete("sources") if hash.key?("sources")
        ordered["notes"]       = hash.delete("notes") if hash.key?("notes")
        ordered.merge!(hash)
        strip_falsey_concept_ref_flags!(ordered)
        ordered.compact!

        YAML.dump(ordered).gsub(/^---\s*\n/, "---\n")
      end

      # Recursively strip `external: false` and `ellipsis: false` from
      # ConceptRef hashes inside the hyperedge's wire output. Keeps
      # YAML clean — these flags only appear when true.
      def strip_falsey_concept_ref_flags!(hash)
        hash.each_value do |value|
          case value
          when Hash
            value.delete("external") if value["external"] == false
            value.delete("ellipsis") if value["ellipsis"] == false
            strip_falsey_concept_ref_flags!(value)
          when Array
            value.each { |item| strip_falsey_concept_ref_flags!(item) if item.is_a?(Hash) }
          end
        end
      end
    end
  end
end
