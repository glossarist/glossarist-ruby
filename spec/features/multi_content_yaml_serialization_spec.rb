RSpec.describe "Serialization and deserialization" do
  context "with multi content YAML" do
    let(:concept_folder) { "multi_content_yaml" }
    let(:concept_files) do
      Dir.glob(
        File.join(fixtures_path(concept_folder), "concept", "*.{yaml,yml}"),
      )
    end

    let(:concept_yaml) do
      <<~YAML
        ---
        data:
          identifier: '1'
          localized_concepts:
            eng: 3a75582e-699c-4e08-b26a-3ebd6fb00101
            fra: 3a75582e-699c-4e08-b26a-3ebd6fb00102
            rus: 3a75582e-699c-4e08-b26a-3ebd6fb00103
            deu: 3a75582e-699c-4e08-b26a-3ebd6fb00104
        id: 3a75582e-699c-4e08-b26a-3ebd6fb00100
        date_accepted: '2023-01-01T00:00:00+00:00'
        status: valid
      YAML
    end

    let(:localized_concept_eng) do
      <<~YAML
        ---
        data:
          dates:
          - date: '2023-01-01T00:00:00+00:00'
            type: accepted
          definition:
          - content: process by which atmospheric gases absorb electromagnetic radiation
          examples: []
          id: 1-EN
          notes: []
          sources:
          - origin:
              ref: ISO 2533:1975
              locality:
                type: clause
                reference_from: 3.2.1
            type: authoritative
          terms:
          - type: expression
            normative_status: preferred
            designation: absorption, atmospheric
          language_code: eng
        date_accepted: '2023-01-01T00:00:00+00:00'
        id: 3a75582e-699c-4e08-b26a-3ebd6fb00101
      YAML
    end

    let(:localized_concept_fra) do
      <<~YAML
        ---
        data:
          dates:
          - date: '2023-01-01T00:00:00+00:00'
            type: accepted
          definition:
          - content: processus par lequel les gaz atmosphériques absorbent le rayonnement
              électromagnétique
          examples: []
          id: 1-FR
          notes: []
          sources:
          - origin:
              ref: ISO 2533:1975
              locality:
                type: clause
                reference_from: 3.2.1
            type: authoritative
          terms:
          - type: expression
            normative_status: preferred
            designation: absorption atmosphérique
          language_code: fra
        date_accepted: '2023-01-01T00:00:00+00:00'
        id: 3a75582e-699c-4e08-b26a-3ebd6fb00102
      YAML
    end

    let(:localized_concept_rus) do
      <<~YAML
        ---
        data:
          dates:
          - date: '2023-01-01T00:00:00+00:00'
            type: accepted
          definition:
          - content: процесс поглощения атмосферными газами электромагнитного излучения
          examples: []
          id: 1-RU
          notes: []
          sources:
          - origin:
              ref: ISO 2533:1975
              locality:
                type: clause
                reference_from: 3.2.1
            type: authoritative
          terms:
          - type: expression
            normative_status: preferred
            designation: атмосферное поглощение
          language_code: rus
        date_accepted: '2023-01-01T00:00:00+00:00'
        id: 3a75582e-699c-4e08-b26a-3ebd6fb00103
      YAML
    end

    let(:localized_concept_deu) do
      <<~YAML
        ---
        data:
          dates:
          - date: '2023-01-01T00:00:00+00:00'
            type: accepted
          definition:
          - content: prozess bei dem atmosphärische Gase elektromagnetische Strahlung absorbieren
          examples: []
          id: 1-DE
          notes: []
          sources:
          - origin:
              ref: ISO 2533:1975
              locality:
                type: clause
                reference_from: 3.2.1
            type: authoritative
          terms:
          - type: expression
            normative_status: preferred
            designation: atmosphärische Absorption
          language_code: deu
        date_accepted: '2023-01-01T00:00:00+00:00'
        id: 3a75582e-699c-4e08-b26a-3ebd6fb00104
      YAML
    end

    it "loads concepts from files" do
      collection = Glossarist::ManagedConceptCollection.new
      collection.load_from_files(fixtures_path(concept_folder))

      expect(collection).to be_a Glossarist::ManagedConceptCollection
      expect(collection.managed_concepts.count).to eq(1)
      expect(collection.managed_concepts.first.data.localizations.is_a?(Hash)).to be true
      expect(collection.managed_concepts.first.data.localizations.keys).to include("eng", "fra", "rus", "deu")
      expect(collection.managed_concepts.first.to_yaml).to eq(concept_yaml)
      expect(collection.managed_concepts.first.data.localizations["eng"].to_yaml).to eq(localized_concept_eng)
      expect(collection.managed_concepts.first.data.localizations["fra"].to_yaml).to eq(localized_concept_fra)
      expect(collection.managed_concepts.first.data.localizations["rus"].to_yaml).to eq(localized_concept_rus)
      expect(collection.managed_concepts.first.data.localizations["deu"].to_yaml).to eq(localized_concept_deu)
    end

    it "saves a concept and its related localized concepts into single file" do
      collection = Glossarist::ManagedConceptCollection.new
      collection.load_from_files(fixtures_path(concept_folder))

      Dir.mktmpdir do |tmp_path|
        collection.save_grouped_concepts_to_files(tmp_path)

        concepts = Dir.glob(File.join(tmp_path, "**", "*.{yaml,yml}"))
        expect(concepts.count).to eq(1)

        file_content = File.read(concepts.first)

        expected_file_content = [
          concept_yaml,
          localized_concept_eng,
          localized_concept_fra,
          localized_concept_rus,
          localized_concept_deu,
        ].join("\n")

        expect(file_content).to eq(expected_file_content)
      end
    end
  end
end
