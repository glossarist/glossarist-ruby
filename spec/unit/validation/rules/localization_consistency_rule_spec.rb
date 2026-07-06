# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::LocalizationConsistencyRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }
  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: dataset_context
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-017") }
  end

  describe "#check" do
    it "passes when map and localizations are consistent" do
      mc = make_managed_concept(id: "x", langs: { eng: {} })
      mc.data.localized_concepts = { "eng" => mc.localization("eng").uuid }
      issues = rule.check(make_context(mc))
      expect(issues).to be_empty
    end

    it "flags map entry with no loaded localization" do
      mc = make_managed_concept(id: "x", langs: { eng: {} })
      mc.data.localized_concepts = {
        "eng" => mc.localization("eng").uuid,
        "fra" => "missing-uuid",
      }
      issues = rule.check(make_context(mc))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("fra")
    end

    it "flags loaded localization not in map" do
      mc = make_managed_concept(id: "x", langs: { eng: {} })
      # map is empty by default; the loaded eng localization has no entry.
      mc.data.localized_concepts = {}
      issues = rule.check(make_context(mc))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("not in localized_concepts map")
    end

    it "flags UUID mismatch between map and localization" do
      mc = make_managed_concept(id: "x", langs: { eng: {} })
      mc.data.localized_concepts = { "eng" => "different-uuid" }
      issues = rule.check(make_context(mc))
      expect(issues.any? { |i| i.message.include?("UUID mismatch") }).to be true
    end
  end
end
