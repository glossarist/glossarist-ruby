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
        concept_from_file = Glossarist::ManagedConcept.from_yaml(File.read(filename))
        concept = collection[concept_from_file.identifier]

        expect(concept.to_yaml_hash["data"]).to eq(concept_from_file.to_yaml_hash["data"])

        concept.localized_concepts.each do |lang, id|
          localized_concept_path = File.join(localized_concepts_folder,
                                             "#{id}.yaml")
          localized_concept = Glossarist::LocalizedConcept.from_yaml(File.read(localized_concept_path))

          expect(localized_concept.to_yaml_hash["data"]).to eq(concept.localizations[lang].to_yaml_hash["data"])
        end
      end

      Dir.mktmpdir do |tmp_path|
        collection.save_to_files(tmp_path)

        expected_dir = fixtures_path(concept_folder)
        Dir.glob(File.join(expected_dir, "concept",
                           "*.yaml")).each do |expected_file|
          actual_file = File.join(tmp_path, "concept",
                                  File.basename(expected_file))
          expect(File.read(actual_file)).to be_yaml_equivalent_to(File.read(expected_file))
        end

        Dir.glob(File.join(expected_dir, "localized_concept",
                           "*.yaml")).each do |expected_file|
          actual_file = File.join(tmp_path, "localized_concept",
                                  File.basename(expected_file))
          expect(File.read(actual_file)).to be_yaml_equivalent_to(File.read(expected_file))
        end
      end
    end
  end

  context "when localizedConcept (with camel case)" do
    let(:concept_folder) { "concept_collection_v2_camel_cased" }
    let(:concept_files) do
      Dir.glob(File.join(fixtures_path(concept_folder), "concept",
                         "*.{yaml,yml}"))
    end
    let(:reference_folder) { "concept_collection_v2" }

    it "correctly loads concepts from camel case files and matches reference format" do
      collection = Glossarist::ManagedConceptCollection.new
      collection.load_from_files(fixtures_path(concept_folder))

      concept_files.each do |filename|
        concept_from_file = Glossarist::ManagedConcept.from_yaml(File.read(filename))
        reference_concept = Glossarist::ManagedConcept.from_yaml(File.read(File.join(
                                                                             fixtures_path(reference_folder), "concept", File.basename(filename)
                                                                           )))

        expect(concept_from_file.to_yaml_hash["data"]).to eq(reference_concept.to_yaml_hash["data"])
      end

      Dir.mktmpdir do |tmp_path|
        collection.save_to_files(tmp_path)

        reference_dir = fixtures_path(reference_folder)
        Dir.glob(File.join(reference_dir, "concept",
                           "*.yaml")).each do |expected_file|
          actual_file = File.join(tmp_path, "concept",
                                  File.basename(expected_file))
          expect(File.read(actual_file)).to be_yaml_equivalent_to(File.read(expected_file))
        end

        Dir.glob(File.join(reference_dir, "localized_concept",
                           "*.yaml")).each do |expected_file|
          actual_file = File.join(tmp_path, "localized_concept",
                                  File.basename(expected_file))
          expect(File.read(actual_file)).to be_yaml_equivalent_to(File.read(expected_file))
        end
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
        concept_from_file = Glossarist::ManagedConcept.from_yaml(File.read(filename))
        concept = collection[concept_from_file.identifier]

        expect(concept.to_yaml_hash["data"]).to eq(concept_from_file.to_yaml_hash["data"])

        concept.localized_concepts.each do |lang, id|
          localized_concept_path = File.join(localized_concepts_folder,
                                             "#{id}.yaml")
          localized_concept = Glossarist::LocalizedConcept.from_yaml(File.read(localized_concept_path))

          expect(localized_concept.to_yaml_hash["data"]).to eq(concept.localizations[lang].to_yaml_hash["data"])
        end
      end

      Dir.mktmpdir do |tmp_path|
        collection.save_to_files(tmp_path)

        expected_dir = fixtures_path(concept_folder)
        Dir.glob(File.join(expected_dir, "concept",
                           "*.yaml")).each do |expected_file|
          actual_file = File.join(tmp_path, "concept",
                                  File.basename(expected_file))
          expect(File.read(actual_file)).to be_yaml_equivalent_to(File.read(expected_file))
        end

        Dir.glob(File.join(expected_dir, "localized-concept",
                           "*.yaml")).each do |expected_file|
          actual_file = File.join(tmp_path, "localized-concept",
                                  File.basename(expected_file))
          expect(File.read(actual_file)).to be_yaml_equivalent_to(File.read(expected_file))
        end
      end
    end
  end
end
