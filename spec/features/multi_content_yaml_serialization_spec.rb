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
        date_accepted: '2023-01-01T00:00:00+00:00'
        status: valid
        id: 3a75582e-699c-4e08-b26a-3ebd6fb00100
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
      store = Glossarist::GlossaryStore.new
      store.load(fixtures_path(concept_folder))

      expect(store.concepts.count).to eq(1)
      concept = store.concepts.first
      expect(concept.data.localizations.is_a?(Glossarist::Collections::LocalizationCollection)).to be true
      expect(concept.data.localizations.keys).to include(
        "eng", "fra", "rus", "deu"
      )
      expect(concept.to_yaml).to eq(concept_yaml)
      expect(concept.data.localizations["eng"].to_yaml).to eq(localized_concept_eng)
      expect(concept.data.localizations["fra"].to_yaml).to eq(localized_concept_fra)
      expect(concept.data.localizations["rus"].to_yaml).to eq(localized_concept_rus)
      expect(concept.data.localizations["deu"].to_yaml).to eq(localized_concept_deu)
    end

    it "saves a concept and its related localized concepts into single file" do
      store = Glossarist::GlossaryStore.new
      store.load(fixtures_path(concept_folder))

      Dir.mktmpdir do |tmp_path|
        doc = Glossarist::V3::ConceptDocument.from_managed_concept(store.concepts.first)
        File.write(File.join(tmp_path, "aaa-111.yaml"), doc.to_yamls)

        concepts = Dir.glob(File.join(tmp_path, "*.{yaml,yml}"))
        expect(concepts.count).to eq(1)

        # Byte form is the writer policy (dump-engine choice); assert
        # data equality on re-parse instead.
        written = File.read(concepts.first, encoding: "utf-8")
        reread = Glossarist::V3::ConceptDocument.from_yamls(written)
        expected = Glossarist::V3::ConceptDocument.from_managed_concept(store.concepts.first)
        expect(reread.to_managed_concept.to_yaml_hash).to eq(expected.to_managed_concept.to_yaml_hash)
        expect(written.scan("{{").count).to eq(written.scan("}}").count)
      end
    end
  end
end
