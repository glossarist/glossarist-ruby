# frozen_string_literal: true

# Unmodified files from https://github.com/geolexica/isotc211-glossary
# Source SHA: 51a22e9fc30cde14edcd65ba5b8317ce6106b3fd (geolexica/).
# One managed concept and all nine referenced localizations, including non-Latin
# designations, legacy status/dateAccepted, review dates and source localities.
#
# Opt-in full dataset check (no network access performed by these specs):
# git clone https://github.com/geolexica/isotc211-glossary /tmp/isotc211-glossary
# git -C /tmp/isotc211-glossary checkout 51a22e9fc30cde14edcd65ba5b8317ce6106b3fd
# ISOTC211_DATASET=/tmp/isotc211-glossary/geolexica bundle exec rspec spec/integration/isotc211_dataset_spec.rb
RSpec.describe "ISO/TC 211 dataset compatibility" do
  include Isotc211Helpers

  let(:fixture) { File.expand_path("../fixtures/isotc211", __dir__) }
  let(:collection) do
    Glossarist::ManagedConceptCollection.new.tap do |concepts|
      concepts.load_from_files(fixture)
    end
  end
  let(:concept_file) { Dir[File.join(fixture, "concept/*.yaml")].fetch(0) }

  it "loads the complete pinned concept and all nine localizations" do
    expect(collection.count).to eq(1)
    concept = collection.first
    expect(concept.localizations.keys).to match_array(%w[eng ara zho fin fra deu kor rus spa])
    expect(YAML.safe_load(concept.to_yaml))
      .to eq(expected_isotc211_document(concept_file))
    concept.localizations.each_value do |localized|
      path = File.join(fixture, "localized-concept", "#{localized.uuid}.yaml")
      expect(YAML.safe_load(localized.to_yaml))
        .to eq(expected_isotc211_document(path, localized: true))
    end
  end

  it "preserves every sample field through collection save and reload" do
    Dir.mktmpdir do |directory|
      collection.save_to_files(directory)
      reloaded = Glossarist::ManagedConceptCollection.new
      reloaded.load_from_files(directory)

      expect(reloaded.count).to eq(1)
      concept = reloaded.first
      expect(YAML.safe_load(concept.to_yaml))
        .to eq(expected_isotc211_document(concept_file))
      expect(concept.localizations.size).to eq(9)
      concept.localizations.each_value do |localized|
        path = File.join(fixture, "localized-concept", "#{localized.uuid}.yaml")
        expect(YAML.safe_load(localized.to_yaml))
          .to eq(expected_isotc211_document(path, localized: true))
      end
    end
  end

  if ENV["ISOTC211_DATASET"]
    it "loads all 1,507 concepts and 9,147 localizations from the full dataset" do
      path = ENV.fetch("ISOTC211_DATASET")
      concepts = Glossarist::ManagedConceptCollection.new
      concepts.load_from_files(path)

      expect(Dir[File.join(path, "concept/*.yaml")].size).to eq(1507)
      expect(concepts.count).to eq(1507)
      localized_ids = concepts.flat_map { |concept| concept.localizations.values.map(&:uuid) }
      files = Dir[File.join(path, "localized-concept/*.yaml")]
      expect(files.size).to eq(9147)
      expect(localized_ids).to match_array(files.map { |file| File.basename(file, ".yaml") })
    end
  end
end
