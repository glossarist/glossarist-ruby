# frozen_string_literal: true

RSpec.describe Glossarist::ConceptSource do
  it_behaves_like "an Enum"

  subject { described_class.from_yaml(attributes) }

  let(:attributes) do
    {
      type: "authoritative",
      status: "identical",
      origin: {
        "ref" => { "source" => "wikipedia", "id" => "123",
                   "version" => "Test version" },
      },
      modification: "Test modification",
    }.to_yaml
  end

  describe "#to_yaml" do
    it "will convert concept source to hash" do
      expected_yaml = <<~YAML
        ---
        origin:
          ref:
            source: wikipedia
            id: '123'
            version: Test version
        status: identical
        type: authoritative
        modification: Test modification
      YAML

      expect(subject.to_yaml).to eq(expected_yaml)
    end
  end

  describe "#type" do
    it "returns type" do
      expect(subject.type).to eq("authoritative")
    end
  end

  describe "#id field" do
    it "defaults to nil when not provided" do
      source = described_class.new(type: "authoritative")
      expect(source.id).to be_nil
    end

    it "stores the provided id" do
      source = described_class.new(id: "iso-7301-3-2", type: "authoritative")
      expect(source.id).to eq("iso-7301-3-2")
    end

    it "round-trips id through to_yaml and from_yaml" do
      source = described_class.new(
        id: "smith-2020",
        type: "lineage",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(
          source: "DOI", id: "10.1234/abc",
        )),
      )
      yaml = source.to_yaml
      restored = described_class.from_yaml(yaml)
      expect(restored.id).to eq("smith-2020")
    end

    it "preserves id through from_yaml" do
      yaml = <<~YAML
        ---
        id: foo
        type: authoritative
        origin:
          ref:
            source: ISO
            id: '7301'
      YAML
      restored = described_class.from_yaml(yaml)
      expect(restored.id).to eq("foo")
    end
  end

  describe "#status" do
    it "returns status" do
      expect(subject.status).to eq("identical")
    end
  end

  describe "#sourced_from" do
    it "defaults to nil when not provided" do
      source = described_class.new(type: "authoritative")
      expect(source.sourced_from).to be_nil
    end

    it "round-trips through to_yaml and from_yaml" do
      source = described_class.new(
        type: "lineage",
        status: "identical",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(
          source: "OIML", id: "G 18", version: "2010",
        )),
        sourced_from: [
          Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(
            source: "OIML", id: "B 3", version: "2003",
          )),
        ],
      )
      yaml = source.to_yaml
      restored = described_class.from_yaml(yaml)
      expect(restored.sourced_from.length).to eq(1)
      expect(restored.sourced_from.first.ref.source).to eq("OIML")
      expect(restored.sourced_from.first.ref.id).to eq("B 3")
    end

    it "round-trips multiple sourced_from entries" do
      yaml = <<~YAML
        ---
        type: lineage
        status: modified
        modification: merged definitions from B 3 and B 4
        origin:
          ref:
            source: OIML
            id: 'G 18'
            version: '2010'
        sourced_from:
        - ref:
            source: OIML
            id: 'B 3'
            version: '2003'
        - ref:
            source: OIML
            id: 'B 4'
            version: '2005'
      YAML
      restored = described_class.from_yaml(yaml)
      expect(restored.sourced_from.length).to eq(2)
      expect(restored.sourced_from[0].ref.id).to eq("B 3")
      expect(restored.sourced_from[1].ref.id).to eq("B 4")
    end

    it "preserves locality in sourced_from entries" do
      yaml = <<~YAML
        ---
        type: lineage
        status: identical
        origin:
          ref:
            source: OIML
            id: 'G 18'
            version: '2010'
        sourced_from:
        - ref:
            source: OIML
            id: 'V 1'
            version: '2000'
          locality:
            type: clause
            reference_from: '3.1'
      YAML
      restored = described_class.from_yaml(yaml)
      expect(restored.sourced_from.length).to eq(1)
      expect(restored.sourced_from.first.locality.type).to eq("clause")
      expect(restored.sourced_from.first.locality.reference_from).to eq("3.1")
    end
  end
end
