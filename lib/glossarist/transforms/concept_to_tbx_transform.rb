# frozen_string_literal: true

require "tbx"

module Glossarist
  module Transforms
    class ConceptToTbxTransform
      def self.transform(managed_concept, options = {})
        new(managed_concept, options).build_entry
      end

      def self.transform_document(concepts, options = {})
        doc = Tbx::Document.new
        body = Tbx::Body.new
        body.concept_entry = concepts.map { |c| transform(c, options) }
        text = Tbx::TextElement.new
        text.body = body
        doc.text = text

        if options[:title]
          header = doc.tbx_header || Tbx::TbxHeader.new
          file_desc = Tbx::FileDesc.new
          title_stmt = Tbx::TitleStmt.new
          title = Tbx::Title.new
          title.content = options[:title]
          title_stmt.title = title
          file_desc.title_stmt = title_stmt
          header.file_desc = file_desc
          doc.tbx_header = header
        end

        doc
      end

      def initialize(managed_concept, options = {})
        @concept = managed_concept
        @options = options
      end

      def build_entry
        entry = Tbx::ConceptEntry.new
        entry.id = concept_id
        entry.lang_sec = build_lang_sections
        entry
      end

      private

      attr_reader :concept, :options

      def concept_id
        prefix = options[:shortname]
        id = concept.data&.id || concept.identifier
        prefix ? "#{prefix}_#{id}" : id.to_s
      end

      def build_lang_sections
        concept.localizations.filter_map do |l10n|
          lang = l10n.language_code
          next unless lang

          ls = Tbx::LangSec.new
          ls.lang = lang

          term = l10n.preferred_terms&.first || l10n.terms&.first
          if term&.designation
            ts = Tbx::TermSec.new
            t = Tbx::Term.new
            t.content = term.designation.to_s
            ts.term = t
            ls.term_sec = ts
          end

          definition = l10n.data&.definition&.first&.content
          if definition
            ds = Tbx::Descrip.new
            ds.content = definition.to_s
            ls.descrip = ds
          end

          ls
        end
      end
    end
  end
end
