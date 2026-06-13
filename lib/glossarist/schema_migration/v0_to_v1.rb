# frozen_string_literal: true

module Glossarist
  class SchemaMigration
    class V0ToV1
      ENTRY_STATUS_MAP = {
        "Standard" => "valid",
        "Confirmed" => "valid",
        "Proposed" => "draft",
      }.freeze

      LANG_CODES = Glossarist::LANG_CODES

      IEV_PATTERN = /\{\{([^,}]+),\s*IEV:([^}]+)\}\}/
      URN_PATTERN = /\{urn:iso:std:iso:(\d+):([^,}]+),([^}]+)\}/

      attr_reader :from_version, :to_version

      def initialize(concept_hash, from_version: "0",
                               to_version: SchemaMigration::CURRENT_SCHEMA_VERSION,
                               ref_maps: {})
        @concept = concept_hash
        @from_version = from_version
        @to_version = to_version
        @ref_maps = ref_maps
      end

      def migrate
        case [from_version, to_version]
        when ["0", "1"] then migrate_v0_to_v1
        else
          raise Errors::Base,
                "Unsupported migration: #{from_version} -> #{to_version}"
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
        if @concept.key?("termid")
          @concept["termid"] =
            String(@concept["termid"])
        end
      end

      def migrate_language_block(lang)
        l10n_block = @concept[lang]
        return unless l10n_block.is_a?(Hash)

        migrate_definition(l10n_block)
        migrate_authoritative_source(l10n_block)
        migrate_dates(l10n_block)
        migrate_entry_status(l10n_block)
        migrate_terms_abbrev(l10n_block)
        extract_inline_refs(l10n_block)
        strip_revisions(l10n_block)
      end

      def migrate_definition(l10n_block)
        return unless l10n_block.key?("definition")
        return unless l10n_block["definition"].is_a?(String)

        l10n_block["definition"] = [{ "content" => l10n_block["definition"] }]
      end

      def migrate_authoritative_source(l10n_block)
        return unless l10n_block.key?("authoritative_source")

        src = l10n_block.delete("authoritative_source")
        return if l10n_block.key?("sources")

        sources = (src.is_a?(Array) ? src : [src]).filter_map do |s|
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
        end

        l10n_block["sources"] = sources if sources.any?
      end

      def migrate_dates(l10n_block)
        return if l10n_block.key?("dates")

        dates = []
        if l10n_block["date_accepted"]
          dates << { "type" => "accepted",
                     "date" => l10n_block["date_accepted"] }
        end
        if l10n_block["date_amended"]
          dates << { "type" => "amended", "date" => l10n_block["date_amended"] }
        end
        l10n_block["dates"] = dates if dates.any?
      end

      def migrate_entry_status(l10n_block)
        return unless l10n_block.key?("entry_status")

        mapped = ENTRY_STATUS_MAP[l10n_block["entry_status"]]
        l10n_block["entry_status"] = mapped if mapped
      end

      def migrate_terms_abbrev(l10n_block)
        return unless l10n_block["terms"].is_a?(Array)

        l10n_block["terms"].each do |term|
          next unless term.is_a?(Hash)
          next unless term["abbrev"] == true

          term["type"] = "abbreviation"
          term.delete("abbrev")
        end
      end

      def extract_inline_refs(l10n_block)
        texts = []

        if l10n_block["definition"].is_a?(Array)
          l10n_block["definition"].each do |d|
            texts << (d.is_a?(Hash) ? d["content"].to_s : d.to_s)
          end
        elsif l10n_block["definition"].is_a?(String)
          texts << l10n_block["definition"]
        end

        Array(l10n_block["notes"]).each do |n|
          texts << (n.is_a?(Hash) ? n["content"].to_s : n.to_s)
        end
        Array(l10n_block["examples"]).each do |e|
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

        existing = l10n_block["references"] || []
        seen_ids = existing.to_set { |r| r["concept_id"] || r["id"] }
        refs.each do |ref|
          key = ref["concept_id"] || ref["id"]
          next if seen_ids.include?(key)

          seen_ids.add(key)
          existing << ref
        end
        l10n_block["references"] = existing
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
end
