# frozen_string_literal: true

module Glossarist
  class GcrStatistics < Lutaml::Model::Serializable
    attribute :total_concepts, :integer
    attribute :languages, :string, collection: true
    attribute :concepts_by_status, :hash
    attribute :concepts_with_definitions, :integer
    attribute :concepts_with_sources, :integer

    key_value do
      map :total_concepts, to: :total_concepts
      map :languages, to: :languages
      map :concepts_by_status, to: :concepts_by_status
      map :concepts_with_definitions, to: :concepts_with_definitions
      map :concepts_with_sources, to: :concepts_with_sources
    end

    def self.from_concepts(concepts)
      l10ns = concepts.flat_map { |c| c.localizations.to_a }

      new(
        total_concepts: concepts.length,
        languages: l10ns.map(&:language_code).compact.sort.uniq,
        concepts_by_status: l10ns.map(&:entry_status).compact.tally,
        concepts_with_definitions: count_with(l10ns, :definition),
        concepts_with_sources: count_with(l10ns, :sources),
      )
    end

    def self.count_with(l10ns, attr)
      l10ns.count { |l| l.data.send(attr)&.any? }
    end
  end
end
