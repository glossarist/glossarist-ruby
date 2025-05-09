RSpec.describe "Serialization and deserialization" do
  context "when localized_concept (with underscore as separator)" do
    let(:concept_folder) { "concept_collection_v2" }
    let(:concept_files) do
      Dir.glob(File.join(fixtures_path(concept_folder), "concept",
                         "*.{yaml,yml}"))
    end
    let(:localized_concepts_folder) do
      File.join(fixtures_path(concept_folder), "localized_concept")
    end

    it "correctly loads concepts from files" do
      collection = Glossarist::ManagedConceptCollection.new
      collection.load_from_files(fixtures_path(concept_folder))

      concept_files.each do |filename|
        concept_from_file = load_yaml_file(filename)
        concept = collection[concept_from_file["data"]["identifier"]]

        expect(concept.to_yaml_hash["data"]).to eq(concept_from_file["data"])

        concept.localized_concepts.each do |lang, id|
          localized_concept_path = File.join(localized_concepts_folder,
                                             "#{id}.yaml")
          localized_concept = load_yaml_file(localized_concept_path)

          expect(localized_concept["data"]).to eq(concept.localizations[lang].to_yaml_hash["data"])
        end
      end

      Dir.mktmpdir do |tmp_path|
        collection.save_to_files(tmp_path)

        # check if concept and localized_concept folder exist
        system "diff", fixtures_path(concept_folder), tmp_path
        expect($?.exitstatus).to eq(0) # no difference

        # check content of conecept folder
        system "diff", File.join(fixtures_path(concept_folder), "concept"),
               File.join(tmp_path, "concept")
        expect($?.exitstatus).to eq(0) # no difference

        # check content of localized_conecept folder
        system "diff",
               File.join(fixtures_path(concept_folder), "localized_concept"), File.join(tmp_path, "localized_concept")
        expect($?.exitstatus).to eq(0) # no difference
      end
    end
  end

  context "when localizedConcept (with camel case)" do
    let(:concept_folder) { "concept_collection_v2_camel_cased" }
    let(:concept_files) { Dir.glob(File.join(fixtures_path(concept_folder), "concept", "*.{yaml,yml}")) }
    let(:localized_concepts_folder) { File.join(fixtures_path(concept_folder), "localized_concept") }
    let(:reference_folder) { "concept_collection_v2" }

    it "correctly loads concepts from camel case files and matches reference format" do
      collection = Glossarist::ManagedConceptCollection.new
      collection.load_from_files(fixtures_path(concept_folder))

      concept_files.each do |filename|
        concept_from_file = load_yaml_file(filename)
        concept = collection[concept_from_file["data"]["identifier"]]
        reference_concept = load_yaml_file(File.join(fixtures_path(reference_folder), "concept", File.basename(filename)))

        expect(concept.to_yaml_hash["data"]).to eq(reference_concept["data"])
      end

      Dir.mktmpdir do |tmp_path|
        collection.save_to_files(tmp_path)

        # Compare with reference format
        system "diff", fixtures_path(reference_folder), tmp_path
        expect($?.exitstatus).to eq(0) # no difference

        system "diff", File.join(fixtures_path(reference_folder), "concept"), File.join(tmp_path, "concept")
        expect($?.exitstatus).to eq(0) # no difference

        system "diff", File.join(fixtures_path(reference_folder), "localized_concept"), File.join(tmp_path, "localized_concept")
        expect($?.exitstatus).to eq(0) # no difference
      end
    end
  end

  context "when localized-concept (with dash as separator)" do
    let(:concept_folder) { "concept_collection_v2_dashed" }
    let(:concept_files) do
      Dir.glob(File.join(fixtures_path(concept_folder), "concept",
                         "*.{yaml,yml}"))
    end
    let(:localized_concepts_folder) do
      File.join(fixtures_path(concept_folder), "localized-concept")
    end

    it "correctly loads concepts from files" do
      collection = Glossarist::ManagedConceptCollection.new
      collection.load_from_files(fixtures_path(concept_folder))

      concept_files.each do |filename|
        concept_from_file = load_yaml_file(filename)
        concept = collection[concept_from_file["data"]["identifier"]]

        expect(concept.to_yaml_hash["data"]).to eq(concept_from_file["data"])

        concept.localized_concepts.each do |lang, id|
          localized_concept_path = File.join(localized_concepts_folder,
                                             "#{id}.yaml")
          localized_concept = load_yaml_file(localized_concept_path)

          expect(localized_concept["data"]).to eq(concept.localizations[lang].to_yaml_hash["data"])
        end
      end

      Dir.mktmpdir do |tmp_path|
        collection.save_to_files(tmp_path)

        # check if concept and localized-concept folder exist
        system "diff", fixtures_path(concept_folder), tmp_path
        expect($?.exitstatus).to eq(0) # no difference

        # check content of conecept folder
        system "diff", File.join(fixtures_path(concept_folder), "concept"),
               File.join(tmp_path, "concept")
        expect($?.exitstatus).to eq(0) # no difference

        # check content of localized-conecept folder
        system "diff",
               File.join(fixtures_path(concept_folder), "localized-concept"), File.join(tmp_path, "localized-concept")
        expect($?.exitstatus).to eq(0) # no difference
      end
    end
  end

  def load_yaml_file(filename)
    Psych.safe_load(File.read(filename), permitted_classes: [Date])
  end
end
