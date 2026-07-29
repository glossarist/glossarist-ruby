# frozen_string_literal: true

require "yaml"
require "pathname"

module Glossarist
  module V3
    # RelationLoader — scans a directory for per-file n-ary relation
    # files and returns typed instances.
    #
    # Files live at `relations/<comprehensive-id>/<criterion-slug>.yaml`.
    # The `type` field on each file discriminates between
    # PartitiveRelation, GenericRelation, and future n-ary types.
    #
    # Usage:
    #   relations = RelationLoader.load_all("path/to/dataset/relations")
    #   partitive = RelationLoader.load_for_concept("path/to/dataset", "5-1")
    class RelationLoader
      TYPE_TO_CLASS = {
        "partitive_relation" => PartitiveRelation,
        "generic_relation" => GenericRelation,
      }.freeze

      LoadError = Class.new(::StandardError)

      class << self
        # Load every relation file under `dir`. Returns a hash keyed
        # by comprehensive id, value = array of typed relations.
        def load_all(dir)
          new(dir).load_all
        end

        # Load all relation files for a single comprehensive id.
        # `dataset_root` is the path containing the `relations/` directory.
        def load_for_concept(dataset_root, comprehensive_id)
          new(File.join(dataset_root, "relations")).load_for_comprehensive(comprehensive_id)
        end

        # Load a single relation file. Returns a typed instance
        # (PartitiveRelation, GenericRelation, etc.).
        def load_file(path)
          new(File.dirname(File.dirname(path))).load_path(path)
        end
      end

      def initialize(relations_dir)
        @relations_dir = Pathname.new(relations_dir)
      end

      def load_all
        each_relation_path.with_object({}) do |path, h|
          rel = load_path(path)
          comp_id = comprehensive_id_of(rel)
          (h[comp_id] ||= []) << rel
        end
      end

      def load_for_comprehensive(comprehensive_id)
        dir = @relations_dir.join(comprehensive_id.to_s)
        return [] unless dir.exist?

        Dir.glob("#{dir}/*.yaml").sort.map { |p| load_path(Pathname.new(p)) }
      end

      def load_path(path)
        path = Pathname.new(path)
        doc = YAML.load_file(path)
        unless doc.is_a?(Hash) && doc["type"]
          raise LoadError, "#{path} missing required `type` field"
        end

        klass = TYPE_TO_CLASS[doc["type"]]
        unless klass
          raise LoadError, "#{path} has unknown type #{doc['type'].inspect}; " \
                            "expected one of #{TYPE_TO_CLASS.keys.join(', ')}"
        end

        klass.from_hash(doc)
      end

      private

      def each_relation_path
        return enum_for(:each_relation_path) unless block_given?
        return [] unless @relations_dir.exist?

        Dir.glob("#{@relations_dir}/**/*.yaml").sort.each do |p|
          yield Pathname.new(p)
        end
      end

      def comprehensive_id_of(relation)
        ref = relation.comprehensive
        return nil unless ref.is_a?(ConceptRef) && ref.id
        [ref.source, ref.id].compact.join(":")
      end
    end
  end
end
