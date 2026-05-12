# frozen_string_literal: true

require "tmpdir"
require_relative "import_result"

module Glossarist
  module Sts
    class Importer
      STRATEGIES = %i[skip replace merge].freeze

      attr_reader :duplicate_strategy

      def initialize(duplicate_strategy: :skip)
        unless STRATEGIES.include?(duplicate_strategy)
          raise ArgumentError,
                "duplicate_strategy must be one of #{STRATEGIES.join(', ')}, got #{duplicate_strategy}"
        end

        @duplicate_strategy = duplicate_strategy
        @mapper = TermMapper.new
      end

      def import_new(xml_files, output:, shortname: nil, version: nil, **opts)
        raw_concepts = extract_all_concepts(xml_files)
        concepts, conflicts, skipped = dedup_concepts(raw_concepts)

        if output.end_with?(".gcr")
          unless shortname
            raise ArgumentError,
                  "--shortname is required for GCR output"
          end
          unless version
            raise ArgumentError,
                  "--version is required for GCR output"
          end

          create_gcr(concepts, output, shortname: shortname, version: version,
                                       **opts)
        else
          save_dataset(concepts, output)
        end

        ImportResult.new(
          concepts: concepts,
          conflicts: conflicts,
          source_files: xml_files,
          skipped_count: skipped,
        )
      end

      def import_into_existing(xml_files, dataset_path)
        existing = load_existing(dataset_path)
        new_concepts = extract_all_concepts(xml_files)
        index = build_concept_index(existing)

        result_state = apply_with_dedup(new_concepts, existing, index)

        save_to_path(existing, dataset_path)

        ImportResult.new(
          concepts: existing.managed_concepts,
          conflicts: result_state.conflicts,
          source_files: xml_files,
          skipped_count: result_state.skipped,
        )
      end

      DedupState = Struct.new(:conflicts, :skipped, keyword_init: true)

      private

      def apply_with_dedup(new_concepts, existing, index)
        state = DedupState.new(conflicts: [], skipped: 0)

        new_concepts.each do |mc|
          key = concept_key(mc)
          existing_mc = index[key]

          if existing_mc.nil?
            existing.store(mc)
            index[key] = mc
          else
            state.conflicts << DuplicateConflict.new(
              new_concept: mc, existing_concept: existing_mc, key: key,
            )
            handle_duplicate(existing, existing_mc, mc, index, key, state)
          end
        end

        state
      end

      def handle_duplicate(existing, old_mc, new_mc, index, key, state)
        case duplicate_strategy
        when :skip
          state.skipped += 1
        when :replace
          replace_in_collection(existing, old_mc, new_mc)
          index[key] = new_mc
        when :merge
          merge_concept(old_mc, new_mc)
        end
      end

      def extract_all_concepts(xml_files)
        xml_files.flat_map do |path|
          extractor = TermExtractor.new(path)
          terms = extractor.extract
          terms.map { |t| @mapper.map(t) }
        end
      end

      def dedup_concepts(concepts) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        seen = {}
        conflicts = []
        skipped = 0
        unique = []

        concepts.each do |mc|
          key = concept_key(mc)
          if key.first.empty? || seen[key].nil?
            unique << mc
            seen[key] = mc unless key.first.empty?
          else
            conflicts << DuplicateConflict.new(
              new_concept: mc, existing_concept: seen[key], key: key,
            )
            skipped += apply_dedup_to_unique(unique, seen, mc, key)
          end
        end

        [unique, conflicts, skipped]
      end

      def apply_dedup_to_unique(unique, seen, new_mc, key)
        case duplicate_strategy
        when :skip
          1
        when :replace
          unique.delete(seen[key])
          unique << new_mc
          seen[key] = new_mc
          0
        when :merge
          merge_concept(seen[key], new_mc)
          0
        end
      end

      def concept_key(managed_concept)
        designation = managed_concept.default_designation.to_s.downcase.strip
        domain = begin
          l10n = managed_concept.default_lang
          l10n&.data&.domain.to_s.downcase.strip
        end
        [designation, domain]
      end

      def build_concept_index(collection)
        index = {}
        collection.each do |mc|
          key = concept_key(mc)
          index[key] = mc unless key.first.empty?
        end
        index
      end

      def merge_concept(existing_mc, new_mc)
        new_mc.localizations.each do |l10n|
          lang = l10n.language_code
          if existing_mc.localization(lang).nil?
            existing_mc.add_localization(l10n)
          end
        end
      end

      def replace_in_collection(collection, old_mc, new_mc)
        collection.managed_concepts.delete(old_mc)
        collection.store(new_mc)
      end

      def load_existing(path)
        collection = ManagedConceptCollection.new
        if path.end_with?(".gcr")
          package = GcrPackage.load(path)
          package.concepts.each { |mc| collection.store(mc) }
        else
          concepts = ConceptCollector.collect(path)
          concepts.each { |mc| collection.store(mc) }
        end
        collection
      end

      def save_to_path(collection, path)
        if path.end_with?(".gcr")
          tmpdir = build_temp_dataset(collection.managed_concepts)
          begin
            GC.start
            tmp_gcr = "#{path}.tmp.#{Process.pid}"
            GcrPackage.create_from_directory(
              tmpdir,
              output: tmp_gcr,
              shortname: File.basename(path, ".gcr"),
              version: "1.0.0",
            )
            FileUtils.rm_f(path)
            FileUtils.mv(tmp_gcr, path)
          ensure
            FileUtils.rm_rf(tmpdir)
            FileUtils.rm_f(tmp_gcr)
          end
        else
          save_dataset(collection.managed_concepts, path)
        end
      end

      def save_dataset(concepts, dir)
        concepts_dir = File.join(dir, "concepts")
        FileUtils.mkdir_p(concepts_dir)
        collection = ManagedConceptCollection.new
        concepts.each { |mc| collection.store(mc) }
        collection.save_grouped_concepts_to_files(concepts_dir)
      end

      def create_gcr(concepts, output, shortname:, version:, **opts)
        tmpdir = build_temp_dataset(concepts)
        begin
          GcrPackage.create_from_directory(
            tmpdir,
            output: output,
            shortname: shortname,
            version: version,
            **opts,
          )
        ensure
          FileUtils.rm_rf(tmpdir)
        end
      end

      def build_temp_dataset(concepts)
        tmpdir = Dir.mktmpdir("glossarist-sts-import")
        concepts_dir = File.join(tmpdir, "concepts")
        FileUtils.mkdir_p(concepts_dir)

        collection = ManagedConceptCollection.new
        concepts.each { |mc| collection.store(mc) }
        collection.save_grouped_concepts_to_files(concepts_dir)

        tmpdir
      end
    end
  end
end
