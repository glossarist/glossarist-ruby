# frozen_string_literal: true

module Glossarist
  class ConceptCollector
    def self.collect(dir)
      dir = File.expand_path(dir)
      unless File.directory?(dir)
        raise ArgumentError, "#{dir} is not a directory"
      end

      if v2_concepts?(dir)
        collect_v2_concepts(dir)
      elsif managed_concepts?(dir)
        collect_managed_concepts(dir)
      elsif v1_concepts?(dir)
        collect_v1_concepts(dir)
      else
        []
      end
    end

    def self.each_concept(dir, &block)
      dir = File.expand_path(dir)
      unless File.directory?(dir)
        raise ArgumentError, "#{dir} is not a directory"
      end
      return enum_for(:each_concept, dir) unless block

      if v2_concepts?(dir)
        each_v2_concept(dir, &block)
      elsif managed_concepts?(dir)
        each_managed_concept(dir, &block)
      elsif v1_concepts?(dir)
        each_v1_concept(dir, &block)
      end
    end

    class << self
      private

      def v1_concepts?(dir)
        concepts_dir = File.join(dir, "concepts")
        File.directory?(concepts_dir) &&
          Dir.glob(File.join(concepts_dir, "*.yaml")).any? do |f|
            V1::Concept.from_file(f)&.termid?
          end
      end

      def v2_concepts?(dir)
        File.directory?(File.join(dir, "geolexica-v2"))
      end

      def managed_concepts?(dir)
        concept_dir = File.join(dir, "concepts", "concept")
        File.directory?(concept_dir) &&
          Dir.glob(File.join(concept_dir, "*.yaml")).any?
      end

      def collect_v1_concepts(dir)
        concepts = []
        each_v1_concept(dir) { |mc| concepts << mc }
        concepts
      end

      def each_v1_concept(dir)
        concepts_dir = File.join(dir, "concepts")
        files = Dir.glob(File.join(concepts_dir, "*.yaml"))
        files.each do |file|
          v1 = V1::Concept.from_file(file)
          next unless v1

          yield v1.to_managed_concept
        end
      end

      def collect_v2_concepts(dir)
        v2_dir = File.join(dir, "geolexica-v2")
        if File.directory?(File.join(v2_dir, "concepts"))
          collect_managed_concepts(v2_dir)
        else
          collect_grouped_v2_concepts(v2_dir)
        end
      end

      def each_v2_concept(dir, &block)
        v2_dir = File.join(dir, "geolexica-v2")
        if File.directory?(File.join(v2_dir, "concepts"))
          each_managed_concept(v2_dir, &block)
        else
          each_grouped_v2_concept(v2_dir, &block)
        end
      end

      def each_grouped_v2_concept(v2_dir, &block)
        collection = ManagedConceptCollection.new
        manager = ConceptManager.new(path: v2_dir)
        manager.load_from_files(collection: collection)
        collection.each(&block)
      end

      def collect_grouped_v2_concepts(v2_dir)
        collection = ManagedConceptCollection.new
        manager = ConceptManager.new(path: v2_dir)
        manager.load_from_files(collection: collection)
        collection.to_a
      end

      def collect_managed_concepts(dir) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        concepts = []
        each_managed_concept(dir) { |mc| concepts << mc }
        concepts
      end

      def each_managed_concept(dir) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        concepts_dir = File.join(dir, "concepts")
        concept_files = Dir.glob(File.join(concepts_dir, "concept", "*.yaml"))
        return if concept_files.empty?

        lc_dir = find_localized_concepts_dir(concepts_dir)
        lc_index = build_lc_index(lc_dir) if lc_dir

        concept_files.each do |f|
          mc = ManagedConcept.from_yaml(File.read(f))
          next unless mc.data&.id

          lc_map = mc.data.localized_concepts || {}
          lc_map.each_value do |uuid|
            lc_file = lc_index ? lc_index[uuid] : nil
            next unless lc_file

            l10n = LocalizedConcept.from_yaml(File.read(lc_file))
            mc.add_localization(l10n)
          end

          yield mc
        end
      end

      def build_lc_index(lc_dir)
        Dir.glob(File.join(lc_dir, "*.{yaml,yml}"))
          .to_h { |f| [File.basename(f, ".*"), f] }
      end

      def find_localized_concepts_dir(concepts_dir)
        %w[localized_concept localized-concept].each do |name|
          d = File.join(concepts_dir, name)
          return d if File.directory?(d)
        end
        nil
      end
    end
  end
end
