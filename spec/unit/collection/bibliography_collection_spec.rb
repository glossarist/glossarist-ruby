# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Collections::BibliographyCollection do
  subject { described_class.new(concepts, nil, relaton_cache_path) }

  let(:concepts) do
    collection = Glossarist::ManagedConceptCollection.new
    collection.load_from_files(fixtures_path("concept_collection_v2"))
    collection
  end

  let(:relaton_cache_path) { fixtures_path("relaton_cache") }

  it "populated bibliography correctly" do
    items = subject.fetch_all
    expect(items.size).to be 1
    expect(items[0]).to be_instance_of Relaton::Iso::Bibdata
  end

  it "fetches the correct record" do
    item = subject.fetch "ISO/TS 14812:2022"
    expect(item).to be_instance_of(Relaton::Iso::Bibdata)
  end

  describe "version mismatch" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:iso_dir) { "#{temp_dir}/iso" }

    before { FileUtils.mkdir_p(iso_dir) }
    after { FileUtils.rm_rf(temp_dir) }

    it "raises CacheVersionMismatchError on fetch_all when version is wrong" do
      File.write("#{iso_dir}/version", "wrong")

      processor = instance_double("processor", grammar_hash: "correct_hash")
      allow(Relaton::Registry.instance).to receive(:by_type)
        .with("iso").and_return(processor)

      collection = described_class.new(concepts, nil, temp_dir)

      expect { collection.fetch_all }.to raise_error(
        Glossarist::CacheVersionMismatchError, /version mismatch/
      )
    end
  end
end
