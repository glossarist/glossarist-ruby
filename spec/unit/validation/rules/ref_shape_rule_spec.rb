# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::RefShapeRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }
  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_concept(sources:, related: [])
    mc = make_managed_concept(id: "x", langs: { eng: { sources: sources } })
    mc.related = related if related.any?
    mc
  end

  def make_context(concept)
    make_concept_context(concept, collection_context: dataset_context)
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-305") }
  end

  describe "#category" do
    it { expect(rule.category).to eq(:schema) }
  end

  describe "#check" do
    it "passes for well-formed Citation::Ref" do
      ref = Glossarist::Citation::Ref.new(source: "ISO", id: "9000")
      origin = Glossarist::Citation.new(ref: ref)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept(sources: [source])

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end

    it "flags nil ref" do
      origin = Glossarist::Citation.new(ref: nil)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept(sources: [source])

      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("nil ref")
    end

    it "flags empty ref (no source or id)" do
      ref = Glossarist::Citation::Ref.new
      origin = Glossarist::Citation.new(ref: ref)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept(sources: [source])

      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("neither source nor id")
    end

    it "flags RelatedConcept with empty ref" do
      concept_ref = Glossarist::ConceptRef.new
      related = [Glossarist::RelatedConcept.new(content: "test", type: "broader",
                                                ref: concept_ref)]
      concept = make_concept(sources: [], related: related)

      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("empty ref")
    end

    it "passes for RelatedConcept with valid ref" do
      concept_ref = Glossarist::ConceptRef.new(source: "ISO/TS 14812",
                                               id: "section-3-1")
      related = [Glossarist::RelatedConcept.new(content: "test", type: "broader",
                                                ref: concept_ref)]
      concept = make_concept(sources: [], related: related)

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end
  end
end
