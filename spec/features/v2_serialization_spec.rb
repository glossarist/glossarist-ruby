RSpec.describe "Serialization and deserialization" do
  let(:concept_folder) { "concept_collection_v2" }
  let(:concept_files) { Dir.glob(File.join(fixtures_path(concept_folder), "concept", "*.{yaml,yml}")) }
  let(:localized_concepts_folder) { File.join(fixtures_path(concept_folder), "localized_concept") }

  it "correctly loads concepts from files" do
    collection = Glossarist::ManagedConceptCollection.new
    collection.load_from_files(fixtures_path(concept_folder))

    concept_files.each do |filename|
      concept_from_file = load_yaml_file(filename)
      concept = collection[concept_from_file["data"]["identifier"]]

      expect(concept.to_h["data"]).to eq(concept_from_file["data"])

      concept.localized_concepts.each do |lang, id|
        localized_concept_path = File.join(localized_concepts_folder, "#{id}.yaml")
        localized_concept = load_yaml_file(localized_concept_path)

        expect(localized_concept["data"]).to eq(concept.localizations[lang].to_h["data"])
      end
    end
  end

  def load_yaml_file(filename)
    Psych.safe_load(File.read(filename), permitted_classes: [Date])
  end
end
