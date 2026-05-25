# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::LocalityCompletenessRule do
  subject(:rule) { described_class.new }

  def make_concept(sources)
    l10n = instance_double(Glossarist::LocalizedConcept)
    allow(l10n).to receive(:data).and_return(
      instance_double(Glossarist::ConceptData, sources: sources)
    )
    concept = instance_double(Glossarist::ManagedConcept)
    allow(concept).to receive(:localizations).and_return([l10n])
    concept
  end

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: nil
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-308") }
  end

  describe "#check" do
    it "passes for complete locality" do
      locality = Glossarist::Locality.new(type: "clause", reference_from: "3.1.3.10")
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref, locality: locality)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept([source])

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end

    it "flags locality with no type" do
      locality = Glossarist::Locality.new(reference_from: "3.1.3.10")
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref, locality: locality)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept([source])

      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("no type")
    end

    it "flags locality with no reference_from" do
      locality = Glossarist::Locality.new(type: "clause")
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref, locality: locality)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept([source])

      issues = rule.check(make_context(concept))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("no reference_from")
    end

    it "passes for source without locality" do
      ref = Glossarist::Citation::Ref.new(source: "ISO/TS 14812:2022")
      origin = Glossarist::Citation.new(ref: ref)
      source = Glossarist::ConceptSource.new(origin: origin)
      concept = make_concept([source])

      issues = rule.check(make_context(concept))
      expect(issues).to be_empty
    end
  end
end
