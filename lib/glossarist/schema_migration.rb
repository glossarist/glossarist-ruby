# frozen_string_literal: true

module Glossarist
  class SchemaMigration
    CURRENT_SCHEMA_VERSION = "1"

    ENTRY_STATUS_MAP = {
      "Standard" => "valid",
      "Confirmed" => "valid",
      "Proposed" => "draft",
    }.freeze

    LANG_CODES = %w[eng ara deu fra spa ita jpn kor pol por srp swe zho rus fin dan nld msa nob nno].freeze

    IEV_PATTERN = /\{\{([^,}]+),\s*IEV:([^}]+)\}\}/
    URN_PATTERN = /\{urn:iso:std:iso:(\d+):([^,}]+),([^}]+)\}/

    attr_reader :from_version, :to_version

    def initialize(concept_hash, from_version: "0", to_version: CURRENT_SCHEMA_VERSION, ref_maps: {})
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

      if src.is_a?(Hash)
        origin = {}
        origin["ref"] = src["ref"] if src["ref"]
        origin["clause"] = src["clause"] if src["clause"]
        origin["link"] = src["link"] if src["link"]
        lc["sources"] = [{ "type" => "authoritative", "origin" => origin }]
      end
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
        lc["definition"].each { |d| texts << (d.is_a?(Hash) ? d["content"].to_s : d.to_s) }
      elsif lc["definition"].is_a?(String)
        texts << lc["definition"]
      end

      Array(lc["notes"]).each { |n| texts << (n.is_a?(Hash) ? n["content"].to_s : n.to_s) }
      Array(lc["examples"]).each { |e| texts << (e.is_a?(Hash) ? e["content"].to_s : e.to_s) }

      full_text = texts.join(" ")

      refs = []

      ref_prefix_map = @ref_maps[:ref_prefix_map] || @ref_maps["ref_prefix_map"] || {}
      urn_standard_map = @ref_maps[:urn_standard_map] || @ref_maps["urn_standard_map"] || {}

      full_text.scan(IEV_PATTERN) do |term, id|
        dataset_id = ref_prefix_map["IEV"]
        next unless dataset_id

        refs << {
          "id" => "https://glossarist.org/#{dataset_id}/concept/#{id}",
          "term" => term.strip,
        }
      end

      full_text.scan(URN_PATTERN) do |std_num, id, term|
        dataset_id = urn_standard_map[std_num]
        next unless dataset_id

        refs << {
          "id" => "https://glossarist.org/#{dataset_id}/concept/#{id}",
          "term" => term.strip,
        }
      end

      return if refs.empty?

      existing = lc["references"] || []
      seen_ids = existing.to_set { |r| r["id"] || r[:id] }
      refs.each do |ref|
        next if seen_ids.include?(ref["id"])

        seen_ids.add(ref["id"])
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
  end
end
