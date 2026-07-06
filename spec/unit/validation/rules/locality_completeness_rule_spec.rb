# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::LocalityCompletenessRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }
  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_context(sources)
    mc = make_managed_concept(id: "x", langs: { eng: { sources: sources } })
    make_concept_context(mc, collection_context: dataset_context)
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-308") }
  end

  describe "#check" do
    it "passes for complete locality" do
      locality = Glossarist::Locality.new(type: "clause",
                                          reference_from: "3.1.3.10")
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref, locality: locality)
      source = Glossarist::ConceptSource.new(origin: origin)
      expect(rule.check(make_context([source]))).to be_empty
    end

    it "flags locality with no type" do
      locality = Glossarist::Locality.new(reference_from: "3.1.3.10")
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref, locality: locality)
      source = Glossarist::ConceptSource.new(origin: origin)
      issues = rule.check(make_context([source]))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("no type")
    end

    it "flags locality with no reference_from" do
      locality = Glossarist::Locality.new(type: "clause")
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref, locality: locality)
      source = Glossarist::ConceptSource.new(origin: origin)
      issues = rule.check(make_context([source]))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("no reference_from")
    end

    it "passes for source without locality" do
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref)
      source = Glossarist::ConceptSource.new(origin: origin)
      expect(rule.check(make_context([source]))).to be_empty
    end
  end
end
