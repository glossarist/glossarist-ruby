# frozen_string_literal: true

RSpec.describe Glossarist::ManagedConceptCollection do
  let(:managed_concept_collection) { Glossarist::ManagedConceptCollection.new }

  describe "#managed_concepts" do
    it "returns an array of managed concepts" do
      managed_concept = Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#managed_concepts=" do
    it "sets managed concepts" do
      managed_concept = Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
      managed_concept_collection.managed_concepts = [managed_concept]

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#to_h" do
    it "returns a hash" do
      managed_concept_collection.store(Glossarist::ManagedConcept.of_yaml("data" => { id: "id" }))

      expect(managed_concept_collection.to_h).to eq(
        "managed_concepts" => [
          {
            "data" => { "identifier" => "id" },
            "id" => "f05ee7c5-ba30-5162-9a63-0831726ca83e",
          },
        ],
      )
    end
  end

  describe "#each" do
    it "iterates over managed concepts" do
      managed_concept_collection.store(Glossarist::ManagedConcept.of_yaml("data" => { id: "id" }))

      expect { |b| managed_concept_collection.each(&b) }
        .to yield_control.once
    end
  end

  describe "#fetch" do
    let(:managed_concept) do
      Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
    end

    it "fetches a managed concept by id" do
      managed_concept_collection.store(managed_concept)
      expect(managed_concept_collection.fetch("id")).to eq(managed_concept)
    end

    it "fetches a managed concept by uuid" do
      managed_concept_collection.store(managed_concept)
      uuid = Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE, managed_concept.to_yaml(except: [:uuid])
      )

      expect(managed_concept_collection.fetch(uuid)).to eq(managed_concept)
    end
  end

  describe "#[]" do
    let(:managed_concept) do
      Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
    end

    it "returns a managed concept by uuid" do
      managed_concept_collection.store(managed_concept)
      uuid = Glossarist::Utilities::UUID.uuid_v5(
        Glossarist::Utilities::UUID::OID_NAMESPACE, managed_concept.to_yaml(except: [:uuid])
      )

      expect(managed_concept_collection[uuid]).to eq(managed_concept)
    end

    it "returns a managed concept by id" do
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection["id"]).to eq(managed_concept)
    end
  end

  describe "#fetch_or_initialize" do
    it "add a managed concept when not present" do
      expect { managed_concept_collection.fetch_or_initialize("new") }
        .to change { managed_concept_collection.fetch("new") }
        .from(nil)
        .to(Glossarist::ManagedConcept)
    end

    it "add and return a managed concept when not present" do
      expect(managed_concept_collection.fetch_or_initialize("new"))
        .to be_an_instance_of(Glossarist::ManagedConcept)
    end

    it "returns a managed concept when present" do
      managed_concept_collection.store(Glossarist::ManagedConcept.of_yaml(data: { id: "new" }))

      expect { managed_concept_collection.fetch_or_initialize("new") }
        .not_to(change { managed_concept_collection.fetch("new") })
    end
  end

  describe "#store" do
    it "adds a managed concept" do
      managed_concept = Glossarist::ManagedConcept.of_yaml("data" => { id: "id" })
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#<<" do
    it "adds a managed concept" do
      managed_concept = Glossarist::ManagedConcept.of_yaml({
                                                             "data" => { "id" => "id" },
                                                           })
      managed_concept_collection << managed_concept

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#by_id_and" do
    let(:collection) { described_class.new }

    it "matches on id alone when version is nil" do
      c = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "uuid-1" })
      c.version = nil
      collection.store(c)
      expect(collection.by_id_and(c.uuid, nil)).to eq(c)
    end

    it "matches on id alone when version is omitted" do
      c = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "uuid-1" })
      collection.store(c)
      expect(collection.by_id_and(c.uuid)).to eq(c)
    end

    it "matches on id and version together" do
      c2010 = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "shared-id" })
      c2010.version = "2010"
      c2024 = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "shared-id2" })
      c2024.version = "2024"
      collection.store(c2010)
      collection.store(c2024)
      expect(collection.by_id_and(c2024.uuid, "2024")).to eq(c2024)
    end

    it "returns nil when no concept has the (id, version) pair" do
      c = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "uuid-1" })
      c.version = "2010"
      collection.store(c)
      expect(collection.by_id_and(c.uuid, "2030")).to be_nil
    end

    it "returns nil when no concept has the id" do
      expect(collection.by_id_and("anything", "2024")).to be_nil
    end

    it "returns nil when version is set but concept version is nil" do
      c = Glossarist::ManagedConcept.of_yaml("data" => { "id" => "uuid-1" })
      collection.store(c)
      expect(collection.by_id_and(c.uuid, "2024")).to be_nil
    end
  end

  describe "#load_from_files" do
    context "Invalid concepts" do
      let(:invalid_concepts_path) { fixtures_path("invalid_concepts") }

      it "skips invalid YAML files without raising" do
        expect do
          managed_concept_collection.load_from_files(invalid_concepts_path)
        end.not_to raise_error
      end
    end

    context "Valid concepts" do
      let(:valid_concepts_path) { fixtures_path("concept_collection_v2") }

      it "will not raise Glossarist::Errors::Parse" do
        expect do
          managed_concept_collection.load_from_files(valid_concepts_path)
        end.not_to raise_error
      end

      it "will read concepts correctly from file" do
        expect do
          managed_concept_collection.load_from_files(valid_concepts_path)
        end.to change { managed_concept_collection.count }.by(4)
      end
    end
  end
end
