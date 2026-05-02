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
        @identifier_resolvers << IdentifierResolver.new(prefix: prefix, resolver: resolver)
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
      m = urn.match(/::#con-([\d-]+)/) || urn.match(/60050-(\d+(?:-\d+)+)(?::[\d-]+)?(?:\z|:)/)
      concept_id = m&.[](1) || ""

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
      refs.select do |ref|
        key = ref.concept_id ? [ref.source, ref.concept_id] : [ref.source, ref.concept_id, ref.term]
        seen.add?(key)
      end
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

    # Unified concept mention pattern: {{...}}
    register_pattern(
      name: :concept_mention,
      regex: /\{\{([^}]+)\}\}/,
    ) { |ext, content| ext.resolve_mention(content) }

    register_identifier_resolver("urn:iec:std:iec:60050") do |ext, identifier, display|
      ext.resolve_iec_urn(identifier, display)
    end

    register_identifier_resolver("urn:iso:std:iso:") do |ext, identifier, display|
      ext.resolve_iso_urn(identifier, display)
    end

    register_identifier_resolver("urn:") do |ext, identifier, display|
      ext.resolve_generic_urn(identifier, display)
    end
  end
end
