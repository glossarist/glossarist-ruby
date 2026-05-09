# frozen_string_literal: true

# (c) Copyright 2021 Ribose Inc.
#

RSpec.describe Glossarist::Collections::BibliographyCollection do
  let(:concepts) do
    collection = Glossarist::ManagedConceptCollection.new
    collection.load_from_files(fixtures_path("concept_collection_v2"))
    collection
  end

  let(:cache_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(cache_dir) }

  describe "version mismatch" do
    let(:iso_dir) { File.join(cache_dir, "iso") }

    before { FileUtils.mkdir_p(iso_dir) }

    it "raises CacheVersionMismatchError on fetch_all when version is wrong" do
      File.write("#{iso_dir}/version", "wrong")

      processor = instance_double("processor", grammar_hash: "correct_hash")
      allow(Relaton::Registry.instance).to receive(:by_type)
        .with("iso").and_return(processor)

      collection = described_class.new(concepts, nil, cache_dir)

      expect { collection.fetch_all }.to raise_error(
        Glossarist::CacheVersionMismatchError, /version mismatch/
      )
    end

    it "does not raise on fetch_all when no version file exists" do
      collection = described_class.new(concepts, nil, cache_dir)
      expect { collection.fetch_all }.not_to raise_error
    end
  end
end
