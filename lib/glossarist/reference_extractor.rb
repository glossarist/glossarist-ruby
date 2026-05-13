# frozen_string_literal: true

require "set"

module Glossarist
  class ReferenceExtractor
    @identifier_resolvers = []
    @patterns = []

    IdentifierResolver = Struct.new(:prefix, :resolver, keyword_init: true)
    Pattern = Struct.new(:name, :regex, :resolver, keyword_init: true)

    class << self
      def register_identifier_resolver(prefix, &resolver)
        @identifier_resolvers << IdentifierResolver.new(prefix: prefix,
                                                        resolver: resolver)
      end

      def register_pattern(name:, regex:, &resolver)
        @patterns << Pattern.new(name: name, regex: regex, resolver: resolver)
      end

      def patterns
        @patterns.dup
      end

      def identifier_resolvers
        @identifier_resolvers.dup
      end
    end

    def extract_from_text(text)
      return [] unless text.is_a?(String)

      refs = []
      self.class.patterns.each do |pattern|
        text.scan(pattern.regex).each do |captures|
          captures = [captures] unless captures.is_a?(Array)
          ref = pattern.resolver.call(self, *captures)
          refs << ref if ref
        end
      end
      deduplicate(refs)
    end

    def extract_from_localized(lc_hash)
      gather_texts(lc_hash).flat_map { |t| extract_from_text(t) }
    end

    def extract_from_concept_hash(concept_hash)
      LANG_CODES.flat_map do |lang|
        next [] unless concept_hash[lang].is_a?(Hash)

        extract_from_localized(concept_hash[lang])
      end
    end

    def extract_from_managed_concept(concept)
      concept.localizations.flat_map do |l10n|
        extract_from_localized_concept(l10n)
      end
    end

    def extract_from_localized_concept(l10n)
      texts = []
      l10n.data.definition&.each { |d| texts << d.content if d.content }
      l10n.data.notes&.each { |n| texts << n.content if n.content }
      l10n.data.examples&.each { |e| texts << e.content if e.content }
      texts.flat_map { |t| extract_from_text(t) }
    end

    # Unified concept mention dispatcher.
    # Content is the text inside {{...}}.
    def resolve_mention(content)
      content = content.strip

      if content.include?(",")
        parts = content.split(",", 2)
        display = parts[0].strip
        identifier = parts[1].strip
        resolve_by_identifier(identifier, display)
      else
        resolve_by_identifier(content, nil)
      end
    end

    def resolve_by_identifier(identifier, display)
      # Check registered identifier resolvers (built-in + custom)
      self.class.identifier_resolvers.each do |ir|
        next unless identifier.start_with?(ir.prefix)

        return ir.resolver.call(self, identifier, display)
      end

      case identifier
      when /\A\d[\d.-]*\z/
        resolve_local(display || identifier, identifier)
      else
        resolve_designation(identifier, display)
      end
    end

    def resolve_local(term, concept_id)
      ConceptReference.new(
        term: term.strip,
        concept_id: concept_id.strip,
        source: nil,
        ref_type: "local",
      )
    end

    def resolve_designation(text, display)
      ConceptReference.new(
        term: display || text,
        concept_id: nil,
        source: nil,
        ref_type: "designation",
      )
    end

    def resolve_iec_urn(urn, display)
      concept_id = extract_iec_concept_id(urn)

      ConceptReference.new(
        term: display || "",
        concept_id: concept_id,
        source: "urn:iec:std:iec:60050",
        ref_type: "urn",
      )
    end

    def resolve_iso_urn(urn, display)
      if (m = urn.match(/\Aurn:iso:std:iso:(\d+)(?::(.*))?\z/))
        term_id = extract_term_id_from_urn_tail(m[2])
        ConceptReference.new(
          term: display || "",
          concept_id: term_id,
          source: "urn:iso:std:iso:#{m[1]}",
          ref_type: "urn",
        )
      end
    end

    def resolve_generic_urn(urn, display)
      ConceptReference.new(
        term: display || "",
        concept_id: nil,
        source: urn,
        ref_type: "urn",
      )
    end

    LANG_CODES = Glossarist::LANG_CODES

    # Extract asset references from model attributes (NonVerbRep, GraphicalSymbol).
    def extract_asset_refs_from_concept(concept)
      refs = []

      concept.localizations.each do |l10n|
        Array(l10n.non_verb_rep).each do |nvr|
          next unless nvr.is_a?(NonVerbRep) && nvr.ref && !nvr.ref.strip.empty?
          refs << AssetReference.new(path: nvr.ref.strip)
        end

        (l10n.data&.terms || []).each do |term|
          if term.is_a?(Designation::GraphicalSymbol) && term.image && !term.image.strip.empty?
            refs << AssetReference.new(path: term.image.strip)
          end
        end
      end

      refs
    end

    # Extract bibliographic xrefs from model-level source citations.
    def extract_bib_refs_from_concept(concept)
      refs = []
      concept.localizations.each do |l10n|
        gather_all_sources(l10n).each do |source|
          origin = source.origin
          next unless origin

          if origin.text && !origin.text.strip.empty?
            refs << BibliographicReference.new(anchor: origin.text)
          end

          next unless origin.source && origin.id

          key = "#{origin.source} #{origin.id}"
          refs << BibliographicReference.new(anchor: key)
          refs << BibliographicReference.new(anchor: origin.id.to_s)
        end
      end
      refs
    end

    # Extract all reference types from a managed concept.
    def extract_all_from_managed_concept(concept)
      concept_refs = extract_from_managed_concept(concept)
      asset_refs = extract_asset_refs_from_concept(concept)
      concept_refs + asset_refs
    end

    def resolve_asciidoc_xref(target)
      BibliographicReference.new(anchor: target.strip)
    end

    def resolve_image_ref(path)
      AssetReference.new(path: path.strip)
    end

    private

    def gather_texts(lc_hash)
      texts = extract_text_fields(lc_hash["definition"])
      texts << lc_hash["definition"].to_s if lc_hash["definition"].is_a?(String)
      texts.concat(extract_text_fields(lc_hash["notes"]))
      texts.concat(extract_text_fields(lc_hash["examples"]))
      texts
    end

    def extract_text_fields(items)
      Array(items).filter_map do |item|
        item.is_a?(Hash) ? item["content"]&.to_s : item.to_s
      end
    end

    def deduplicate(refs)
      seen = Set.new
      refs.select { |ref| seen.add?(ref.dedup_key) }
    end

    def extract_term_id_from_urn_tail(tail)
      return "" unless tail

      if (m = tail.match(/term:([\d.,]+)/))
        m[1].split(",").first
      elsif (m = tail.match(/sec:([\d.]+)/))
        m[1]
      else
        tail
      end
    end

    def extract_iec_concept_id(urn)
      if (m = urn.match(/::#con-([\d-]+)/))
        m[1]
      else
        segments = urn.split(":")
        code_part = segments.find { |s| s.start_with?("60050-") }
        return "" unless code_part

        code_part.delete_prefix("60050-").sub(/-\d{4}-\d{2}\z/, "")
      end
    end

    # Unified concept mention pattern: {{...}}
    register_pattern(
      name: :concept_mention,
      regex: /\{\{([^}]+)\}\}/,
    ) { |ext, content| ext.resolve_mention(content) }

    # AsciiDoc cross-references: <<anchor>> or <<anchor,display text>>
    register_pattern(
      name: :asciidoc_xref,
      regex: /<<([^,>\n]+?)(?:,[^>\n]*)?>>/,
    ) { |ext, target| ext.resolve_asciidoc_xref(target) }

    # Image references: image::path[] or image:path[]
    register_pattern(
      name: :asciidoc_image,
      regex: /image::?([^\[\]]+)\[/,
    ) { |ext, path| ext.resolve_image_ref(path) }

    register_identifier_resolver("urn:iec:std:iec:60050") do |ext, identifier, display|
      ext.resolve_iec_urn(identifier, display)
    end

    register_identifier_resolver("urn:iso:std:iso:") do |ext, identifier, display|
      ext.resolve_iso_urn(identifier, display)
    end

    register_identifier_resolver("urn:") do |ext, identifier, display|
      ext.resolve_generic_urn(identifier, display)
    end

    def gather_all_sources(l10n)
      sources = Array(l10n.data&.sources)
      sources += Array((l10n.data&.definition || []).flat_map(&:sources).compact)
      sources += Array((l10n.data&.notes || []).flat_map(&:sources).compact)
      sources += Array((l10n.data&.examples || []).flat_map(&:sources).compact)
      sources
    end
  end
end
