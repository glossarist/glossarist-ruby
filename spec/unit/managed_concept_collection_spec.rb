# frozen_string_literal: true

RSpec.describe Glossarist::LutamlModel::ManagedConceptCollection do
  let(:managed_concept_collection) { Glossarist::LutamlModel::ManagedConceptCollection.new }

  describe "#managed_concepts" do
    it "returns an array of managed concepts" do
      managed_concept = Glossarist::LutamlModel::ManagedConcept.new(id: "id")
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#managed_concepts=" do
    it "sets managed concepts" do
      managed_concept = Glossarist::LutamlModel::ManagedConcept.new(id: "id")
      managed_concept_collection.managed_concepts = [managed_concept]

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#to_h" do
    it "returns a hash" do
      managed_concept_collection.store(Glossarist::LutamlModel::ManagedConcept.new("data" => { id: "id" }))

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
      managed_concept_collection.store(Glossarist::LutamlModel::ManagedConcept.new("data" => { id: "id" }))

      expect{ |b| managed_concept_collection.each(&b) }
        .to yield_control.once
    end
  end

  describe "#fetch" do
    let(:managed_concept) { Glossarist::LutamlModel::ManagedConcept.new("data" => { id: "id" }) }

    it "fetches a managed concept by id" do
      managed_concept_collection.store(managed_concept)
      expect(managed_concept_collection.fetch("id")).to eq(managed_concept)
    end

    it "fetches a managed concept by uuid" do
      managed_concept_collection.store(managed_concept)
      uuid = Glossarist::Utilities::UUID.uuid_v5(Glossarist::Utilities::UUID::OID_NAMESPACE, managed_concept.to_yaml(except: [:uuid]))

      expect(managed_concept_collection.fetch(uuid)).to eq(managed_concept)
    end
  end

  describe "#[]" do
    let(:managed_concept) { Glossarist::LutamlModel::ManagedConcept.new("data" => { id: "id" }) }

    it "returns a managed concept by uuid" do
      managed_concept_collection.store(managed_concept)
      uuid = Glossarist::Utilities::UUID.uuid_v5(Glossarist::Utilities::UUID::OID_NAMESPACE, managed_concept.to_yaml(except: [:uuid]))

      expect(managed_concept_collection[uuid]).to eq(managed_concept)
    end

    it "returns a managed concept by id" do
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection["id"]).to eq(managed_concept)
    end
  end

  describe "#fetch_or_initialize" do
    it "add a managed concept when not present" do
      expect{ managed_concept_collection.fetch_or_initialize("new") }
        .to change { managed_concept_collection.fetch("new") }
        .from(nil)
        .to(Glossarist::LutamlModel::ManagedConcept)
    end

    it "add and return a managed concept when not present" do
      expect(managed_concept_collection.fetch_or_initialize("new"))
        .to be_an_instance_of(Glossarist::LutamlModel::ManagedConcept)
    end

    it "returns a managed concept when present" do
      managed_concept_collection.store(Glossarist::LutamlModel::ManagedConcept.new(data: { id: "new" }))

      expect{ managed_concept_collection.fetch_or_initialize("new") }
        .not_to change { managed_concept_collection.fetch("new") }
    end
  end

  describe "#store" do
    it "adds a managed concept" do
      managed_concept = Glossarist::LutamlModel::ManagedConcept.new(id: "id")
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#<<" do
    it "adds a managed concept" do
      managed_concept = Glossarist::LutamlModel::ManagedConcept.new(id: "id")
      managed_concept_collection << managed_concept

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#load_from_files" do
    context "Invalid concepts" do
      let(:invalid_concepts_path) { fixtures_path("invalid_concepts") }

      it "will raise Glossarist::ParseError" do
        expect do
          managed_concept_collection.load_from_files(invalid_concepts_path)
        end.to raise_error(Glossarist::ParseError)
      end
    end

    context "Valid concepts" do
      let(:valid_concepts_path) { fixtures_path("concept_collection_v2") }

      it "will not raise Glossarist::ParseError" do
        expect do
          managed_concept_collection.load_from_files(valid_concepts_path)
        end.not_to raise_error(Glossarist::ParseError)
      end

      it "will read concepts correctly from file" do
        expect do
          managed_concept_collection.load_from_files(valid_concepts_path)
        end.to change { managed_concept_collection.count }.by(4)
      end
    end
  end
end
