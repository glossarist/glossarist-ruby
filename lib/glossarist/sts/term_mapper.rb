# frozen_string_literal: true

module Glossarist
  module Sts
    class TermMapper
      def map(extracted_term)
        concept_id = extracted_term.label || extracted_term.id

        mc = Glossarist::ManagedConcept.new(data: { id: concept_id })

        extracted_term.lang_sets.each do |ls|
          mc.add_localization(build_localized_concept(ls,
                                                      extracted_term.source_ref))
        end

        mc
      end

      private

      def build_localized_concept(lang_set, source_ref)
        terms = lang_set.designations.map { |d| build_designation(d) }

        Glossarist::LocalizedConcept.of_yaml(
          "data" => {
            "language_code" => lang_set.language_code,
            "terms" => terms,
            "definition" => build_definitions(lang_set.definition_text),
            "notes" => build_detailed_definitions(lang_set.note_texts),
            "examples" => build_detailed_definitions(lang_set.example_texts),
            "sources" => build_sources(lang_set.source_texts, source_ref),
            "domain" => lang_set.domain,
            "entry_status" => "valid",
          },
        )
      end

      def build_definitions(text)
        return [] unless text && !text.empty?

        [{ "content" => text }]
      end

      def build_detailed_definitions(texts)
        texts.filter_map do |text|
          next if text.empty?

          { "content" => text }
        end
      end

      def build_designation(ext_desig)
        case ext_desig.type
        when "abbreviation"
          build_abbreviation_designation(ext_desig)
        when "symbol"
          build_symbol_designation(ext_desig)
        else
          build_expression_designation(ext_desig)
        end
      end

      def build_expression_designation(ext_desig)
        hash = {
          "type" => "expression",
          "designation" => ext_desig.term,
          "normative_status" => ext_desig.normative_status,
        }.compact

        if ext_desig.part_of_speech
          hash["grammar_info"] =
            [{ "part_of_speech" => ext_desig.part_of_speech }]
        end

        hash
      end

      def build_abbreviation_designation(ext_desig)
        {
          "type" => "abbreviation",
          "designation" => ext_desig.term,
          "normative_status" => ext_desig.normative_status,
          "abbreviation_type" => ext_desig.abbreviation_type,
        }.compact
      end

      def build_symbol_designation(ext_desig)
        {
          "type" => "symbol",
          "designation" => ext_desig.term,
          "normative_status" => ext_desig.normative_status,
        }.compact
      end

      def build_sources(source_texts, source_ref)
        sources = []
        if source_ref
          sources << {
            "status" => "identical",
            "type" => "authoritative",
            "origin" => { "text" => source_ref },
          }
        end

        source_texts.each do |text|
          next if text.empty?

          sources << {
            "type" => "authoritative",
            "origin" => { "text" => text },
          }
        end

        sources
      end
    end
  end
end
