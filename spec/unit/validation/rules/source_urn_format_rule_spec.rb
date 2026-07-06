# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::SourceUrnFormatRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }
  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: dataset_context
    )
  end

  def make_concept(sources:, domains: [])
    mc = make_managed_concept(id: "x", langs: { eng: { sources: sources } })
    mc.data.domains = domains if domains.any?
    mc
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
      expect(rule.check(make_context(concept))).to be_empty
    end

    it "passes for non-URN source" do
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept(sources: [source])
      expect(rule.check(make_context(concept))).to be_empty
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
      expect(rule.check(make_context(concept))).to be_empty
    end
  end
end
