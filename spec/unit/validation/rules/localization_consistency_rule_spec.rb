# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::LocalizationConsistencyRule do
  subject(:rule) { described_class.new }

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: nil
    )
  end

  def make_l10n(lang, uuid)
    l10n = instance_double(Glossarist::LocalizedConcept)
    allow(l10n).to receive(:language_code).and_return(lang)
    allow(l10n).to receive(:uuid).and_return(uuid)
    l10n
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-017") }
  end

  describe "#check" do
    it "passes when map and localizations are consistent" do
      l10n = make_l10n("eng", "abc-123")
      data = instance_double(Glossarist::ManagedConceptData,
                             localized_concepts: { "eng" => "abc-123" })
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(concept).to receive(:localizations).and_return([l10n])

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end

    it "flags map entry with no loaded localization" do
      data = instance_double(Glossarist::ManagedConceptData,
                             localized_concepts: { "eng" => "abc-123",
                                                   "fra" => "def-456" })
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      l10n = make_l10n("eng", "abc-123")
      allow(concept).to receive(:localizations).and_return([l10n])

      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("fra")
    end

    it "flags loaded localization not in map" do
      l10n = make_l10n("eng", "abc-123")
      data = instance_double(Glossarist::ManagedConceptData,
                             localized_concepts: {})
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(concept).to receive(:localizations).and_return([l10n])

      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("not in localized_concepts map")
    end

    it "flags UUID mismatch between map and localization" do
      l10n = make_l10n("eng", "wrong-uuid")
      data = instance_double(Glossarist::ManagedConceptData,
                             localized_concepts: { "eng" => "abc-123" })
      concept = instance_double(Glossarist::ManagedConcept, data: data)
      allow(concept).to receive(:localizations).and_return([l10n])

      issues = rule.check(make_context(concept))
      expect(issues.any? { |i| i.message.include?("UUID mismatch") }).to be true
    end
  end
end
