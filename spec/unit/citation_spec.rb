# frozen_string_literal: true

RSpec.describe Glossarist::Citation do
  describe "Citation::Ref" do
    it "round-trips through YAML" do
      ref = Glossarist::Citation::Ref.new(
        source: "ISO", id: "1087-1:2000", version: "2019",
      )
      yaml = ref.to_yaml
      parsed = described_class::Ref.from_yaml(yaml)
      expect(parsed.source).to eq("ISO")
      expect(parsed.id).to eq("1087-1:2000")
      expect(parsed.version).to eq("2019")
    end
  end

  describe "structured ref (V3 format)" do
    let(:src) do
      {
        "ref" => {
          "source" => "Example source",
          "id" => "12345",
          "version" => "2020",
        },
        "locality" => {
          "type" => "issue",
          "reference_from" => "777",
          "reference_to" => "888",
        },
        "link" => "https://example.com",
        "original" => "original ref text",
      }.to_yaml
    end

    it "loads structured ref from YAML" do
      retval = described_class.from_yaml(src)

      expect(retval).to be_kind_of(Glossarist::Citation)
      expect(retval.ref).to be_kind_of(Glossarist::Citation::Ref)
      expect(retval.ref.source).to eq("Example source")
      expect(retval.ref.id).to eq("12345")
      expect(retval.ref.version).to eq("2020")
      expect(retval.locality).to be_kind_of(Glossarist::Locality)
      expect(retval.locality.type).to eq("issue")
      expect(retval.locality.reference_from).to eq("777")
      expect(retval.locality.reference_to).to eq("888")
      expect(retval.link).to eq("https://example.com")
      expect(retval.original).to eq("original ref text")
    end

    it "round-trips structured ref through YAML" do
      retval = described_class.from_yaml(src)
      round_tripped = described_class.from_yaml(retval.to_yaml)

      expect(round_tripped.ref.source).to eq("Example source")
      expect(round_tripped.ref.id).to eq("12345")
      expect(round_tripped.ref.version).to eq("2020")
      expect(round_tripped.locality.type).to eq("issue")
      expect(round_tripped.link).to eq("https://example.com")
    end
  end

  describe "clause locality" do
    it "loads clause shorthand as locality" do
      src = {
        "ref" => { "source" => "ISO", "id" => "9000" },
        "clause" => "12.3",
      }.to_yaml

      retval = described_class.from_yaml(src)
      expect(retval.locality).to be_kind_of(Glossarist::Locality)
      expect(retval.locality.type).to eq("clause")
      expect(retval.locality.reference_from).to eq("12.3")
    end
  end

  describe "custom locality" do
    it "round-trips custom locality" do
      src = {
        "ref" => {
          "source" => "Example source",
          "id" => "12345",
          "version" => "2020",
        },
        "custom_locality" => [
          { "name" => "version", "value" => "5" },
          { "name" => "schema", "value" => "3" },
        ],
      }.to_yaml

      retval = described_class.from_yaml(src)

      expect(retval.ref.source).to eq("Example source")
      expect(retval.ref.id).to eq("12345")
      expect(retval.ref.version).to eq("2020")
      expect(retval.custom_locality).to be_kind_of(Array)
      expect(retval.custom_locality.size).to eq(2)
      expect(retval.custom_locality[0]).to be_kind_of(Glossarist::CustomLocality)
      expect(retval.custom_locality[0].name).to eq("version")
      expect(retval.custom_locality[0].value).to eq("5")
      expect(retval.custom_locality[1]).to be_kind_of(Glossarist::CustomLocality)
      expect(retval.custom_locality[1].name).to eq("schema")
      expect(retval.custom_locality[1].value).to eq("3")
    end
  end

  describe "link and original" do
    it "round-trips link and original" do
      src = {
        "ref" => { "source" => "ISO", "id" => "9000" },
        "link" => "https://example.com",
        "original" => "original ref text",
      }.to_yaml

      retval = described_class.from_yaml(src)
      expect(retval.link).to eq("https://example.com")
      expect(retval.original).to eq("original ref text")

      round_tripped = described_class.from_yaml(retval.to_yaml)
      expect(round_tripped.link).to eq("https://example.com")
      expect(round_tripped.original).to eq("original ref text")
    end
  end

  describe "invalid locality type" do
    it "raises validation error" do
      src = {
        "ref" => {
          "source" => "Example source",
          "id" => "12345",
          "version" => "2020",
        },
        "locality" => {
          "type" => "invalid",
          "reference_from" => "777",
          "reference_to" => "888",
        },
        "link" => "https://example.com",
        "original" => "original ref text",
      }.to_yaml

      expect do
        described_class.from_yaml(src)
      end.to raise_error(Lutaml::Model::ValidationError)
    end
  end

  describe "document identity and item path" do
    let(:tech_citation) do
      described_class.new(
        ref: described_class::Ref.new(
          source: "urn:iso:std:iso:10303:-2:ed-1:en:tech:ACTIVITY_MIM:tech:ACTIVITY_MIM",
          id: "ACTIVITY_MIM",
        ),
      )
    end

    it "splits a tech URN into document identity and item path" do
      expect(tech_citation.document_urn)
        .to eq("urn:iso:std:iso:10303:-2:ed-1:en")
      expect(tech_citation.item_path)
        .to eq("tech:ACTIVITY_MIM:tech:ACTIVITY_MIM")
    end

    it "splits a term URN at its term segment" do
      citation = described_class.new(
        ref: described_class::Ref.new(
          source: "urn:iso:std:iso:10241-1:ed-1:en:term:design",
        ),
      )
      expect(citation.document_urn)
        .to eq("urn:iso:std:iso:10241-1:ed-1:en")
      expect(citation.item_path).to eq("term:design")
    end

    it "returns the full URN as document identity when it has no item path" do
      citation = described_class.new(
        ref: described_class::Ref.new(source: "urn:iso:std:iso:10303:-2:ed-1:en"),
      )
      expect(citation.document_urn).to eq("urn:iso:std:iso:10303:-2:ed-1:en")
      expect(citation.item_path).to be_nil
    end

    it "returns no document identity for a non-URN source" do
      citation = described_class.new(
        ref: described_class::Ref.new(source: "ISO 9000", id: "9000"),
      )
      expect(citation.document_urn).to be_nil
      expect(citation.item_path).to be_nil
    end

    it "returns no document identity without a ref" do
      expect(described_class.new.document_urn).to be_nil
      expect(described_class.new.item_path).to be_nil
    end
  end
end
