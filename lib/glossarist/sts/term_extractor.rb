# frozen_string_literal: true

module Glossarist
  module Sts
    class TermExtractor
      def initialize(xml_path)
        raw = File.read(xml_path)
        @standard = ::Sts::IsoSts::Standard.from_xml(raw)
        @source_ref = extract_source_ref
        @std_prefix = extract_std_prefix(@source_ref)
      end

      def extract
        term_secs = collect_term_secs
        term_secs.filter_map do |ts|
          next unless ts.term_entry

          build_extracted_term(ts)
        end
      end

      private

      def collect_term_secs
        secs = []
        walk_sections(@standard.body, secs) if @standard.body
        secs
      end

      def walk_sections(container, collected)
        collect_term_secs_from(container, collected)
        walk_child_secs(container, collected)
      end

      def collect_term_secs_from(container, collected)
        secs = container.term_sec
        secs&.each do |ts|
          collected << ts
          walk_sections(ts, collected) if ts.term_sec&.any?
        end
      end

      def walk_child_secs(container, collected)
        secs = container_child_secs(container)
        secs&.each { |s| walk_sections(s, collected) }
      end

      def container_child_secs(container)
        case container
        when ::Sts::IsoSts::Body, ::Sts::IsoSts::Sec
          container.sec
        end
      end

      def build_extracted_term(term_sec)
        entry = term_sec.term_entry
        label_text = extract_label(term_sec)

        lang_sets = entry.lang_set.filter_map do |ls|
          build_lang_set(ls)
        end

        Sts::ExtractedTerm.new(
          id: entry.id,
          label: label_text,
          source_ref: @source_ref,
          lang_sets: lang_sets,
        )
      end

      def extract_label(term_sec)
        label = term_sec.label
        return nil unless label

        label.content&.join.to_s.strip
      end

      def build_lang_set(lang_set) # rubocop:disable Metrics/AbcSize
        lang_code = Sts.convert_language_code(lang_set.lang.to_s)

        Sts::ExtractedLangSet.new(
          language_code: lang_code,
          definition_text: extract_definition_text(lang_set),
          note_texts: extract_note_texts(lang_set),
          example_texts: extract_example_texts(lang_set),
          source_texts: extract_source_texts(lang_set),
          domain: extract_subject_field(lang_set),
          designations: lang_set.tig.filter_map do |tig|
            build_designation(tig)
          end,
        )
      end

      ELEMENT_NAME_TO_ATTR = {
        "entailedTerm" => :entailed_term,
        "xref" => :xref,
        "italic" => :italic,
        "bold" => :bold,
        "sup" => :sup,
        "sub" => :sub,
        "monospace" => :monospace,
        "std" => :std,
        "math" => :math,
        "inline-formula" => :inline_formula,
        "list" => :list,
        "styled-content" => :styled_content,
        "ext-link" => :ext_link,
      }.freeze

      def extract_definition_text(lang_set)
        definitions = lang_set.definition
        return "" unless definitions&.any?

        extract_mixed_text(definitions.first)
      end

      def extract_note_texts(lang_set)
        lang_set.note.filter_map do |n|
          text = extract_mixed_text(n)
          text unless text.empty?
        end
      end

      def extract_example_texts(lang_set)
        lang_set.example.filter_map do |e|
          text = extract_mixed_text(e)
          text unless text.empty?
        end
      end

      def extract_mixed_text(mixed_element)
        indices = Hash.new(0)
        parts = []

        mixed_element.element_order.each do |elem|
          if elem.node_type == :text
            parts << elem.text_content.to_s
          else
            attr_name = ELEMENT_NAME_TO_ATTR[elem.name]
            next unless attr_name

            collection = mixed_element.class.attributes.key?(attr_name) &&
              mixed_element.public_send(attr_name)
            next unless collection

            child = collection[indices[elem.name]]
            if child
              if elem.name == "entailedTerm"
                parts << format_entailed_term(child)
              else
                text = child_value_text(child)
                parts << text if text
              end
            end
            indices[elem.name] += 1
          end
        end

        normalize_whitespace(parts.join)
      end

      # entailedTerm → "{{19135:2026:3.5.1,concept}}"
      # format: {{concept_id, render_text}}
      def format_entailed_term(entailed)
        raw_text = entailed.value.to_s
        designation = raw_text.gsub(/\s+\(\d[\d.]*\)\s*\z/, "").strip
        section = extract_section_from_target(entailed.target)

        if @std_prefix && section
          "{{#{@std_prefix}:#{section},#{designation}}}"
        else
          raw_text.strip
        end
      end

      # "term_3.5.1" → "3.5.1", "term_3.8.2-1" → "3.8.2"
      def extract_section_from_target(target)
        return nil unless target

        match = target.match(/term_(\d+(?:\.\d+)*)/)
        match ? match[1] : nil
      end

      def child_value_text(child)
        val = child.value
        case val
        when Array then val.join.to_s
        when String then val
        end
      end

      def extract_source_texts(lang_set)
        lang_set.source.filter_map do |s|
          text = s.value&.join.to_s.strip
          text unless text.empty?
        end
      end

      def extract_subject_field(lang_set)
        fields = lang_set.subject_field
        return nil unless fields&.any?

        text = fields.first.value&.join.to_s.strip
        text unless text.empty?
      end

      def build_designation(tig)
        Sts::ExtractedDesignation.new(
          term: resolve_term_text(tig),
          type: map_term_type(tig),
          normative_status: map_normative_status(tig),
          part_of_speech: tig.pos&.value,
          abbreviation_type: map_abbreviation_type(tig),
        )
      end

      def resolve_term_text(tig)
        tig.term&.value&.join.to_s.strip
      end

      def map_term_type(tig)
        raw = tig.term_type&.value.to_s
        mapped = TERM_TYPE_MAP[raw]
        mapped.nil? || raw.empty? ? "expression" : mapped
      end

      def map_abbreviation_type(tig)
        raw = tig.term_type&.value.to_s
        return nil unless TERM_TYPE_MAP[raw] == "abbreviation"

        raw == "acronym" ? "acronym" : "truncation"
      end

      def map_normative_status(tig)
        NORMATIVE_STATUS_MAP[tig.normative_authorization&.value.to_s]
      end

      def extract_source_ref # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        front = @standard.front
        return nil unless front

        meta = front.iso_meta || front.std_meta
        return nil unless meta

        refs = meta.std_ref
        return nil unless refs&.any?

        best_ref = refs.find { |r| r.type == "dated" } ||
          refs.find { |r| r.type == "undated" } ||
          refs.first

        extract_ref_text(best_ref)
      end

      def extract_ref_text(ref)
        case ref
        when ::Sts::IsoSts::StdRef
          normalize_whitespace(ref.content.join.to_s)
        when ::Sts::NisoSts::StandardRef
          normalize_whitespace(ref.value.to_s)
        else
          ""
        end
      end

      def normalize_whitespace(text)
        text.gsub(/[\s\u00a0]+/, " ").strip
      end

      # "ISO 19101-1:2014" → "19101-1:2014", "ISO/TS 19130-2:2014" → "TS-19130-2:2014"
      def extract_std_prefix(source_ref)
        return nil unless source_ref

        match = source_ref.match(/\AISO(?:\/(\p{Upper}+))? (\d+(?:-\d+)?):(\d+)\z/)
        return nil unless match

        type_part = match[1]
        number = match[2]
        year = match[3]

        type_part ? "#{type_part}-#{number}:#{year}" : "#{number}:#{year}"
      end
    end
  end
end
