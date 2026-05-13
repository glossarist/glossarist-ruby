# frozen_string_literal: true

module Glossarist
  module V1
    class Concept < Lutaml::Model::Serializable
      KNOWN_KEYS = %w[termid term groups references].freeze

      attribute :termid, :string
      attribute :term, :string
      attribute :groups, :string, collection: true
      attribute :references, :hash, collection: true
      attribute :language_blocks, :hash, default: -> { {} }

      key_value do
        map :termid, to: :termid
        map :term, to: :term
        map :groups, to: :groups
        map :references, to: :references, render_nil: false
        map nil, to: :language_blocks,
                 with: { from: :lang_blocks_from, to: :lang_blocks_to }
      end

      def self.from_file(path)
        return nil unless path && File.exist?(path)

        concept = from_yaml(File.read(path))
        return nil unless concept&.termid?

        concept
      rescue Psych::SyntaxError, Lutaml::Model::InvalidFormatError
        nil
      end

      def termid?
        !!termid && !termid.empty?
      end

      def to_managed_concept
        mc = ManagedConcept.new(data: { id: termid })

        language_blocks.each_value do |data|
          mc.add_localization(LocalizedConcept.of_yaml({ "data" => data }))
        end

        assign_domains(mc) if groups.is_a?(Array) && groups.any?
        assign_references(mc) if references.is_a?(Array) && references.any?

        mc
      end

      private

      def assign_domains(concept)
        concept.data.domains = groups.map do |g|
          ConceptReference.new(concept_id: g.to_s, ref_type: "domain")
        end
      end

      def assign_references(concept)
        l10n = concept.localization("eng") || concept.localizations.values.first
        return unless l10n

        l10n.data.references = references.map do |r|
          ConceptReference.new(r.transform_keys(&:to_sym))
        end
      end

      def lang_blocks_from(model, value)
        blocks = {}
        value.each do |key, v|
          next if KNOWN_KEYS.include?(key)
          next unless v.is_a?(Hash)

          data = v.dup
          data["language_code"] ||= key
          blocks[key] = data
        end
        model.language_blocks = blocks
      end

      def lang_blocks_to(model, doc)
        model.language_blocks.each do |lang, data|
          doc[lang] = data
        end
      end
    end
  end
end
