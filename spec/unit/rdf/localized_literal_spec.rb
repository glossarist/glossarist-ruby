# frozen_string_literal: true

require "spec_helper"
require "lutaml/jsonld"
require "lutaml/turtle"
require "glossarist/rdf"

RSpec.describe Glossarist::Rdf::LocalizedLiteral do
  subject(:literal) do
    described_class.new(value: "test value", language_code: "eng")
  end

  describe "#value" do
    it "returns the value" do
      expect(literal.value).to eq("test value")
    end
  end

  describe "#language_code" do
    it "returns the language code" do
      expect(literal.language_code).to eq("eng")
    end
  end

  describe "#to_s" do
    it "returns the value as a string" do
      expect(literal.to_s).to eq("test value")
    end
  end

  describe "serialization" do
    it "round-trips through key_value" do
      hash = literal.to_hash
      restored = described_class.from_hash(hash)
      expect(restored.value).to eq("test value")
      expect(restored.language_code).to eq("eng")
    end
  end
end
