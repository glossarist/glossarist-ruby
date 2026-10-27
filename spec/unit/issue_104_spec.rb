# frozen_string_literal: true

RSpec.describe "Issue 104 YAML compatibility" do
  let(:extensions) do
    { "part" => 2, "document" => "ISO 10303-2",
      "schema" => { "name" => "example", "versions" => [1, 2] } }
  end
  let(:localized_yaml) do
    { "id" => "localized-id", "status" => "valid", "unknown" => "ignored",
      "data" => { "language_code" => "eng", "unknown" => { "nested" => true } } }
      .merge(extensions).to_yaml
  end

  around do |example|
    Dir.mktmpdir do |directory|
      Dir.chdir(directory) do
        File.write("glossarist.yaml",
                   { "extension_attributes" => extensions.keys }.to_yaml)
        example.run
      end
    end
  end

  before do
    config = Glossarist::Config.send(:new)
    allow(Glossarist::Config).to receive(:instance).and_return(config)
  end

  [Glossarist::LocalizedConcept, Glossarist::V2::LocalizedConcept,
   Glossarist::V3::LocalizedConcept].each do |model_class|
    context "with #{model_class}" do
      it "preserves the legacy status through YAML round trips" do
        concept = model_class.from_yaml(localized_yaml)

        expect(concept.entry_status).to eq("valid")
        expect(model_class.from_yaml(concept.to_yaml).entry_status).to eq("valid")
      end

      it "delegates the status setter to entry status" do
        concept = model_class.new
        concept.status = "valid"

        expect(concept.entry_status).to eq("valid")
        expect(model_class.from_yaml(concept.to_yaml).entry_status).to eq("valid")
      end

      it "preserves configured extensions through YAML round trips" do
        concept = model_class.from_yaml(localized_yaml)

        expect(concept.extension_attributes).to eq(extensions)
        expect(model_class.from_yaml(concept.to_yaml).extension_attributes)
          .to eq(extensions)
      end
    end
  end

  it "ignores unknown concept keys at the top level and under data" do
    concept = Glossarist::Concept.from_yaml(
      { "id" => "concept-id", "unknown" => true,
        "data" => { "language_code" => "eng", "unknown" => [1, 2] } }.to_yaml,
    )

    expect(concept.uuid).to eq("concept-id")
    expect(concept.data.language_code).to eq("eng")
  end

  it "preserves explicit extension hashes alongside configured attributes" do
    input = { "data" => {}, "part" => 2,
              "extension_attributes" => { "custom" => false } }
    concept = Glossarist::Concept.of_yaml(input)

    expect(concept.extension_attributes).to eq("custom" => false, "part" => 2)
    expect(input["extension_attributes"]).to eq("custom" => false)
  end

  it "loads and round trips a collection with extraneous keys and extensions" do
    FileUtils.mkdir_p(%w[dataset/concept dataset/localized_concept])
    File.write("dataset/concept/managed.yaml",
               { "id" => "managed-id", "unknown" => true,
                 "data" => { "identifier" => "term-id", "unknown" => true,
                             "localized_concepts" => { "eng" => "localized-id" } } }.to_yaml)
    File.write("dataset/localized_concept/localized-id.yaml", localized_yaml)
    collection = Glossarist::ManagedConceptCollection.new
    collection.load_from_files("dataset")

    expect(collection.count).to eq(1)
    localized = collection.managed_concepts.first.localization("eng")
    expect(localized.entry_status).to eq("valid")
    expect(localized.extension_attributes).to eq(extensions)

    collection.save_to_files("round-trip")
    reloaded = Glossarist::ManagedConceptCollection.new
    reloaded.load_from_files("round-trip")
    localized = reloaded.managed_concepts.first.localization("eng")
    expect(localized.entry_status).to eq("valid")
    expect(localized.extension_attributes).to eq(extensions)
  end
end
