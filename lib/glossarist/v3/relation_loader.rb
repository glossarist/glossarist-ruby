# frozen_string_literal: true

require "yaml"
require "pathname"

module Glossarist
  module V3
    # RelationLoader — scans a directory for per-file hyperedge files
    # and returns typed instances.
    #
    # Files live at `relations/<comprehensive-id>/<criterion-slug>.yaml`.
    # The `type` field on each file discriminates which concrete
    # hyperedge class to instantiate. Dispatch is via HyperedgeRegistry
    # — adding a new hyperedge type requires no edit here.
    #
    # Usage:
    #   relations = RelationLoader.load_all("path/to/dataset/relations")
    #   partitive = RelationLoader.load_for_concept("path/to/dataset", "5-1")
    class RelationLoader
      class LoadError < ::StandardError
      end

      class << self
        # Load every relation file under `dir`. Returns a hash keyed
        # by comprehensive id, value = array of typed hyperedges.
        def load_all(dir)
          new(dir).load_all
        end

        # Load all relation files for a single comprehensive id.
        # `dataset_root` is the path containing the `relations/` directory.
        def load_for_concept(dataset_root, comprehensive_id)
          new(File.join(dataset_root, "relations")).load_for_comprehensive(comprehensive_id)
        end

        # Load a single relation file. Returns a typed hyperedge
        # instance (PartitiveHyperedge, GenericHyperedge, etc.).
        def load_file(path)
          new(File.dirname(path, 2)).load_path(path)
        end
      end

      def initialize(relations_dir)
        @relations_dir = Pathname.new(relations_dir)
      end

      def load_all
        each_relation_path.with_object({}) do |path, h|
          rel = load_path(path)
          comp_id = Glossarist::ConceptRef.qualified_id(rel.comprehensive)
          (h[comp_id] ||= []) << rel
        end
      end

      def load_for_comprehensive(comprehensive_id)
        dir = @relations_dir.join(comprehensive_id.to_s)
        return [] unless dir.exist?

        Dir.glob("#{dir}/*.yaml").map { |p| load_path(Pathname.new(p)) }
      end

      def load_path(path)
        path = Pathname.new(path)
        doc = YAML.load_file(path)
        unless doc.is_a?(Hash) && doc["type"]
          raise LoadError, "#{path} missing required `type` field"
        end

        klass = HyperedgeRegistry.for_type_tag(doc["type"])
        unless klass
          known = HyperedgeRegistry.all_classes.map { |c| c::TYPE_TAG }.join(", ")
          raise LoadError, "#{path} has unknown type #{doc['type'].inspect}; " \
                           "expected one of #{known}"
        end

        # Preserve the source $id so round-trip writes go to the same
        # file path. Without this, write-back would derive a new path
        # from comprehensive + criterion and could fragment files.
        file_id = doc["$id"]
        instance = klass.from_hash(doc)
        instance.file_id = file_id if file_id && instance.respond_to?(:file_id=)
        instance
      end

      private

      def each_relation_path
        return enum_for(:each_relation_path) unless block_given?

        return unless @relations_dir.exist?

        Dir.glob("#{@relations_dir}/**/*.yaml").each do |p|
          yield Pathname.new(p)
        end
      end
    end
  end
end
