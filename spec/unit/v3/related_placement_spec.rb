# frozen_string_literal: true

require "spec_helper"

# Verifies the V3 MECE rule for `related` placement: V3 puts `related`
# ONLY on ManagedConcept, never on ManagedConceptData. See
# CLAUDE.md "V3 `related` placement (MECE)" and TODO.hyperedges/09.

RSpec.describe "V3 related placement (MECE)" do
  describe Glossarist::V3::ManagedConceptData do
    it "does not serialize `related` at the data level" do
      mcd = described_class.new(id: "test-1")
      expect(mcd.to_hash).not_to have_key("related")
    end

    it "does not map `related` in key_value" do
      mapping = described_class.mappings[:yaml]
      # Mapping#mappings returns an Array of MappingRule; each rule's
      # @name is the source key (Symbol or Array of Symbols for
      # multi-key aliases).
      names = mapping.mappings.flat_map { |r| Array(r.name) }.map(&:to_sym)
      expect(names).not_to include(:related)
    end
  end

  describe Glossarist::V3::ManagedConcept do
    it "serializes `related` at the concept level" do
      mc = described_class.new(
        data: Glossarist::V3::ManagedConceptData.new(id: "test-1"),
      )
      mc.related = [Glossarist::V3::RelatedConcept.new(type: "broader")]
      hash = mc.to_hash
      expect(hash).to have_key("related")
    end
  end

  describe "migration moves data.related → concept.related" do
    let(:v2_concept) do
      mc = Glossarist::ManagedConcept.new
      mc.data.id = "test-1"
      mc.data.localized_concepts = { "eng" => "l10n-uuid" }
      mc.data.related = [
        Glossarist::RelatedConcept.new(type: "broader", content: { "eng" => "Parent" }),
      ]
      mc
    end

    it "V3 output never carries related at the data level after migration" do
      Glossarist::SchemaMigration.migrate_concept(v2_concept, target_version: "3")

      # concept-level related is populated
      expect(v2_concept.related.length).to eq(1)
      # data-level is NOT serialized
      expect(v2_concept.data.to_hash).not_to have_key("related")
    end
  end
end
