# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Collections::BibliographyCollection do
  subject { described_class.new(concepts, nil, relaton_cache_path) }

  let(:concepts) do
    collection = Glossarist::ManagedConceptCollection.new
    collection.load_from_files(fixtures_path("concept_collection"))
    collection
  end

  let(:relaton_cache_path) { fixtures_path("relaton_cache") }

  it "populated bibliography correctly" do
    items = subject.fetch_all
    expect(items.size).to be 1
    expect(items[0]).to be_instance_of RelatonIsoBib::IsoBibliographicItem
  end

  it "fetches the correct record" do
    item = subject.fetch "ISO/TS 14812:2022"
    expect(item).to be_instance_of(RelatonIsoBib::IsoBibliographicItem)
  end
end
