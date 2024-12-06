RSpec.describe "Serialization and deserialization" do
  let(:concept_folder) { "concept_collection_v1" }
  let(:output_folder) { File.join("concept_collection_v1", "output") }
  let(:concept_files) { Dir.glob(File.join(fixtures_path(output_folder), "concept-*.{yaml,yml}")) }

  it "correctly loads concepts from files" do
    collection = Glossarist::LutamlModel::ManagedConceptCollection.new
    collection.load_from_files(fixtures_path(concept_folder))

    concept_files.each do |filename|
      concept_from_file = load_yaml_file(filename)
      concept = collection[concept_from_file["data"]["identifier"]]

      expect(concept.to_h["data"]).to eq(concept_from_file["data"])

      concept.localized_concepts.each do |lang, id|
        localized_concept_path = File.join(localized_concepts_folder, "#{id}.yaml")
        localized_concept = load_yaml_file(localized_concept_path)

        expect(localized_concept["data"]).to eq(concept.localizations[lang].to_h_no_uuid["data"])
      end
    end

    Dir.mktmpdir do |tmp_path|
      collection.save_to_files(tmp_path)

      # check if concept and localized_concept folder exist
      system "diff", fixtures_path(output_folder), tmp_path
      expect($?.exitstatus).to eq(0) # no difference

      # check content of conecept folder
      system "diff", File.join(fixtures_path(output_folder), "concept"), File.join(tmp_path, "concept")
      expect($?.exitstatus).to eq(0) # no difference

      # check content of localized_conecept folder
      system "diff", File.join(fixtures_path(output_folder), "localized_concept"), File.join(tmp_path, "localized_concept")
      expect($?.exitstatus).to eq(0) # no difference
    end
  end

  def load_yaml_file(filename)
    Psych.safe_load(File.read(filename), permitted_classes: [Date])
  end
end
