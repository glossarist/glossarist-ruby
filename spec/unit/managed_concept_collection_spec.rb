# frozen_string_literal: true

RSpec.describe Glossarist::ManagedConceptCollection do
  let(:managed_concept_collection) { Glossarist::ManagedConceptCollection.new }

  describe "#managed_concepts" do
    it "returns an array of managed concepts" do
      managed_concept = Glossarist::ManagedConcept.new(id: "id")
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#managed_concepts=" do
    it "sets managed concepts" do
      managed_concept = Glossarist::ManagedConcept.new(id: "id")
      managed_concept_collection.managed_concepts = [managed_concept]

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#to_h" do
    it "returns a hash" do
      managed_concept_collection.store(Glossarist::ManagedConcept.new(id: "id"))

      expect(managed_concept_collection.to_h).to eq(
        "managed_concepts" => [{ "termid" => "id" }]
      )
    end
  end

  describe "#each" do
    it "iterates over managed concepts" do
      managed_concept_collection.store(Glossarist::ManagedConcept.new(id: "id"))

      expect{ |b| managed_concept_collection.each(&b) }
        .to yield_control.once
    end
  end

  describe "#fetch" do
    it "returns a managed concept" do
      managed_concept = Glossarist::ManagedConcept.new(id: "id")
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection.fetch("id")).to eq(managed_concept)
    end
  end

  describe "#[]" do
    it "returns a managed concept" do
      managed_concept = Glossarist::ManagedConcept.new(id: "id")
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection["id"]).to eq(managed_concept)
    end
  end

  describe "#fetch_or_initialize" do
    it "add and return a managed concept when not present" do
      expect{ managed_concept_collection.fetch_or_initialize("new") }
        .to change { managed_concept_collection.fetch("new") }
        .from(nil)
        .to(Glossarist::ManagedConcept)
    end

    it "returns a managed concept when present" do
      managed_concept_collection.store(Glossarist::ManagedConcept.new(id: "new"))

      expect{ managed_concept_collection.fetch_or_initialize("new") }
        .not_to change { managed_concept_collection.fetch("new") }
    end
  end

  describe "#store" do
    it "adds a managed concept" do
      managed_concept = Glossarist::ManagedConcept.new(id: "id")
      managed_concept_collection.store(managed_concept)

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end

  describe "#<<" do
    it "adds a managed concept" do
      managed_concept = Glossarist::ManagedConcept.new(id: "id")
      managed_concept_collection << managed_concept

      expect(managed_concept_collection.managed_concepts).to eq([managed_concept])
    end
  end
end
