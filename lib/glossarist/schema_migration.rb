# frozen_string_literal: true

require "fileutils"

module Glossarist
  class SchemaMigration
    CURRENT_SCHEMA_VERSION = "1"

    ENTRY_STATUS_MAP = {
      "Standard" => "valid",
      "Confirmed" => "valid",
      "Proposed" => "draft",
    }.freeze

    LANG_CODES = Glossarist::LANG_CODES

    IEV_PATTERN = /\{\{([^,}]+),\s*IEV:([^}]+)\}\}/.freeze
    URN_PATTERN = /\{urn:iso:std:iso:(\d+):([^,}]+),([^}]+)\}/.freeze

    attr_reader :from_version, :to_version

    def initialize(concept_hash, from_version: "0",
                             to_version: CURRENT_SCHEMA_VERSION, ref_maps: {})
      @concept = concept_hash
      @from_version = from_version
      @to_version = to_version
      @ref_maps = ref_maps
    end

    def migrate
      case [from_version, to_version]
      when ["0", "1"] then migrate_v0_to_v1
      else
        raise Error, "Unsupported migration: #{from_version} -> #{to_version}"
      end
      @concept
    end

    def self.upgrade_directory(source_dir, output:, # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
                              target_version: CURRENT_SCHEMA_VERSION,
                              cross_references: nil,
                              dry_run: false)
      source_dir = File.expand_path(source_dir)

      concepts_dir = find_concepts_dir(source_dir)
      unless File.directory?(source_dir)
        raise ArgumentError,
              "#{source_dir} is not a directory"
      end
      unless concepts_dir
        raise ArgumentError,
              "No concept YAML files found in #{source_dir}"
      end

      source_version = detect_schema_version(source_dir)
      ref_maps = load_ref_maps(cross_references)
      concepts = read_and_migrate_concepts(concepts_dir, source_version,
                                           target_version, ref_maps)
      register_data = read_register_yaml(source_dir, target_version)

      write_output(concepts, register_data, output, dry_run)

      {
        concepts: concepts,
        register_data: register_data,
        source_version: source_version,
        target_version: target_version,
        output: File.expand_path(output),
        count: concepts.length,
      }
    end

    private

    def migrate_v0_to_v1
      migrate_termid
      LANG_CODES.each do |lang|
        migrate_language_block(lang) if @concept[lang]
      end
      strip_revisions
    end

    def migrate_termid
      @concept["termid"] = String(@concept["termid"]) if @concept.key?("termid")
    end

    def migrate_language_block(lang)
      lc = @concept[lang]
      return unless lc.is_a?(Hash)

      migrate_definition(lc)
      migrate_authoritative_source(lc)
      migrate_dates(lc)
      migrate_entry_status(lc)
      migrate_terms_abbrev(lc)
      extract_inline_refs(lc)
      strip_revisions(lc)
    end

    def migrate_definition(lc)
      return unless lc.key?("definition")
      return unless lc["definition"].is_a?(String)

      lc["definition"] = [{ "content" => lc["definition"] }]
    end

    def migrate_authoritative_source(lc)
      return unless lc.key?("authoritative_source")

      src = lc.delete("authoritative_source")
      return if lc.key?("sources")

      sources = (src.is_a?(Array) ? src : [src]).map do |s|
        next unless s.is_a?(Hash)

        origin = {}
        origin["ref"] = s["ref"] if s["ref"]
        origin["clause"] = s["clause"] if s["clause"]
        origin["link"] = s["link"] if s["link"]

        entry = { "type" => "authoritative", "origin" => origin }
        if s["relationship"]
          entry["status"] = s["relationship"]["type"] || "identical"
          if s["relationship"]["modification"]
            entry["modification"] =
              s["relationship"]["modification"]
          end
        end
        entry
      end.compact

      lc["sources"] = sources if sources.any?
    end

    def migrate_dates(lc)
      return if lc.key?("dates")

      dates = []
      if lc["date_accepted"]
        dates << { "type" => "accepted", "date" => lc["date_accepted"] }
      end
      if lc["date_amended"]
        dates << { "type" => "amended", "date" => lc["date_amended"] }
      end
      lc["dates"] = dates if dates.any?
    end

    def migrate_entry_status(lc)
      return unless lc.key?("entry_status")

      mapped = ENTRY_STATUS_MAP[lc["entry_status"]]
      lc["entry_status"] = mapped if mapped
    end

    def migrate_terms_abbrev(lc)
      return unless lc["terms"].is_a?(Array)

      lc["terms"].each do |term|
        next unless term.is_a?(Hash)
        next unless term["abbrev"] == true

        term["type"] = "abbreviation"
        term.delete("abbrev")
      end
    end

    def extract_inline_refs(lc)
      texts = []

      if lc["definition"].is_a?(Array)
        lc["definition"].each do |d|
          texts << (d.is_a?(Hash) ? d["content"].to_s : d.to_s)
        end
      elsif lc["definition"].is_a?(String)
        texts << lc["definition"]
      end

      Array(lc["notes"]).each do |n|
        texts << (n.is_a?(Hash) ? n["content"].to_s : n.to_s)
      end
      Array(lc["examples"]).each do |e|
        texts << (e.is_a?(Hash) ? e["content"].to_s : e.to_s)
      end

      full_text = texts.join(" ")

      refs = []

      full_text.scan(IEV_PATTERN) do |term, id|
        refs << {
          "term" => term.strip,
          "concept_id" => id.strip,
          "source" => "urn:iec:std:iec:60050",
          "ref_type" => "urn",
        }
      end

      full_text.scan(URN_PATTERN) do |std_num, id, term|
        refs << {
          "term" => term.strip,
          "concept_id" => id.strip,
          "source" => "urn:iso:std:iso:#{std_num}",
          "ref_type" => "urn",
        }
      end

      return if refs.empty?

      existing = lc["references"] || []
      seen_ids = existing.to_set { |r| r["concept_id"] || r["id"] }
      refs.each do |ref|
        key = ref["concept_id"] || ref["id"]
        next if seen_ids.include?(key)

        seen_ids.add(key)
        existing << ref
      end
      lc["references"] = existing
    end

    def strip_revisions(hash = @concept)
      hash.delete("_revisions")
      LANG_CODES.each do |lang|
        next unless hash[lang].is_a?(Hash)

        hash[lang].delete("_revisions")
      end
    end

    class << self
      private

      def find_concepts_dir(source_dir)
        candidates = [
          File.join(source_dir, "concepts"),
          source_dir,
        ]
        candidates.find { |dir| Dir.glob(File.join(dir, "*.yaml")).any? }
      end

      def detect_schema_version(source_dir)
        register = V1::Register.from_file(File.join(source_dir,
                                                    "register.yaml"))
        register&.schema_version || "0"
      end

      def load_ref_maps(cross_references_path)
        xref = V1::CrossReferences.from_file(cross_references_path)
        xref ? xref.to_ref_maps : {}
      end

      def read_and_migrate_concepts(concepts_dir, source_version, # rubocop:disable Metrics/MethodLength
                                    target_version, ref_maps)
        files = Dir.glob(File.join(concepts_dir, "*.yaml"))
        concepts = []
        errors = 0

        files.each do |file|
          v1 = V1::Concept.from_file(file)
          next unless v1

          migration = new(
            v1.to_yaml_hash,
            from_version: source_version,
            to_version: target_version,
            ref_maps: ref_maps,
          )
          concepts << migration.migrate
        rescue StandardError => e
          errors += 1
          warn "  Error migrating #{File.basename(file)}: #{e.message}" if errors <= 5
        end

        warn "  ... #{errors - 5} more errors" if errors > 5
        concepts
      end

      def read_register_yaml(source_dir, target_version)
        register = V1::Register.from_file(File.join(source_dir,
                                                    "register.yaml"))
        return nil unless register

        data = register.to_h
        data["schema_version"] = target_version
        data
      end

      def write_output(concepts, register_data, output, dry_run) # rubocop:disable Metrics/MethodLength
        output_path = File.expand_path(output)

        if File.extname(output).downcase == ".gcr"
          if dry_run
            puts "Would package #{concepts.length} concepts into #{output_path}"
            return
          end

          v1_concepts = concepts.map { |h| V1::Concept.of_yaml(h).to_managed_concept }
          rd = register_data ? RegisterData.of_yaml(register_data) : nil
          metadata = GcrMetadata.from_concepts(v1_concepts,
                                               register_data: rd)
          GcrPackage.create(
            concepts: v1_concepts,
            metadata: metadata,
            register_data: rd,
            output_path: output_path,
          )
        else
          if dry_run
            puts "Would write #{concepts.length} concepts to #{File.join(
              output_path, 'concepts/'
            )}"
            return
          end

          concepts_out = File.join(output_path, "concepts")
          FileUtils.mkdir_p(concepts_out)

          concepts.each do |concept|
            termid = concept["termid"]
            mc = V1::Concept.of_yaml(concept).to_managed_concept
            File.write(File.join(concepts_out, "#{termid}.yaml"),
                       mc.to_yaml)
          end

          if register_data
            rd = RegisterData.of_yaml(register_data)
            File.write(File.join(output_path, "register.yaml"),
                       rd.to_yaml)
          end
        end
      end
    end
  end
end
