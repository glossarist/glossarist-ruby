# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ConceptContext do
  let(:concept) do
    mc = Glossarist::ManagedConcept.new(data: { id: "1" })
    l10n = Glossarist::LocalizedConcept.of_yaml(
      "data" => {
        "language_code" => "eng",
        "terms" => [{ "type" => "expression", "designation" => "test" }],
        "definition" => [{ "content" => "See {{urn:iec:std:iec:60050-102-01-01, equality}} and <<ISO_9000>>." }],
        "entry_status" => "valid",
      },
    )
    mc.add_localization(l10n)
    mc
  end

  let(:collection_context) do
    instance_double(
      Glossarist::Validation::Rules::DatasetContext,
      asset_index: Glossarist::Validation::AssetIndex.new,
      bibliography_index: Glossarist::Validation::BibliographyIndex.new,
      concept_ids: Set.new(["1"]),
      declared_languages: %w[eng],
      metadata: nil,
      gcr?: false,
    )
  end

  let(:context) do
    described_class.new(
      concept,
      file_name: "concept-1.yaml",
      collection_context: collection_context,
    )
  end

  describe "#references" do
    it "extracts all reference types from concept text" do
      refs = context.references
      expect(refs).not_to be_empty
      concept_refs = refs.grep(Glossarist::ConceptReference)
      bib_refs = refs.grep(Glossarist::BibliographicReference)
      expect(concept_refs).not_to be_empty
      expect(bib_refs).not_to be_empty
    end

    it "memoizes the extraction (single source of truth)" do
      first = context.references
      second = context.references
      expect(first).to be(second)
    end
  end

  describe "#asset_references" do
    let(:concept_with_assets) do
      mc = Glossarist::ManagedConcept.new(data: { id: "2" })
      l10n = Glossarist::LocalizedConcept.of_yaml(
        "data" => {
          "language_code" => "eng",
          "terms" => [{ "type" => "graphical_symbol", "image" => "images/symbol.svg" }],
        },
      )
      mc.add_localization(l10n)
      mc
    end

    let(:context_with_assets) do
      described_class.new(
        concept_with_assets,
        file_name: "concept-2.yaml",
        collection_context: collection_context,
      )
    end

    it "extracts asset references from model attributes" do
      refs = context_with_assets.asset_references
      asset_refs = refs.grep(Glossarist::AssetReference)
      expect(asset_refs).not_to be_empty
      expect(asset_refs.first.path).to eq("images/symbol.svg")
    end

    it "memoizes the extraction" do
      first = context_with_assets.asset_references
      second = context_with_assets.asset_references
      expect(first).to be(second)
    end
  end

  describe "#concept_id" do
    it "returns the concept's data id as string" do
      expect(context.concept_id).to eq("1")
    end
  end
end
