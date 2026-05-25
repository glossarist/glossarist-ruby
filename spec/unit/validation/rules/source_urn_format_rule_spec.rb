# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::SourceUrnFormatRule do
  subject(:rule) { described_class.new }

  def make_concept(sources:, domains: [], related: [])
    l10n = instance_double(Glossarist::LocalizedConcept)
    allow(l10n).to receive(:data).and_return(
      instance_double(Glossarist::ConceptData, sources: sources,
                                                definition: [], notes: [], examples: [])
    )
    data = instance_double(Glossarist::ManagedConceptData, domains: domains)
    concept = instance_double(Glossarist::ManagedConcept)
    allow(concept).to receive(:localizations).and_return([l10n])
    allow(concept).to receive(:data).and_return(data)
    allow(concept).to receive(:related).and_return(related)
    concept
  end

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: nil
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-310") }
  end

  describe "#check" do
    it "passes for valid URN in source" do
      ref = Glossarist::Citation::Ref.new(source: "urn:iso:std:iso:ts:14812")
      origin = Glossarist::Citation.new(ref: ref)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept(sources: [source])

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end

    it "passes for non-URN source" do
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept(sources: [source])

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end

    it "flags malformed URN in source" do
      ref = Glossarist::Citation::Ref.new(source: "urn:not a valid urn!!!")
      origin = Glossarist::Citation.new(ref: ref)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept(sources: [source])

      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("malformed URN")
    end

    it "passes for valid URN in domain" do
      domain = Glossarist::ConceptReference.new(
        urn: "urn:iso:std:iso:ts:14812",
        concept_id: "section-3-1",
      )
      concept = make_concept(sources: [], domains: [domain])

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end
  end
end
