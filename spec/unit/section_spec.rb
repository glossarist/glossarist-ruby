# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Section do
  describe "initialization" do
    it "creates a section with id and names" do
      section = described_class.new(id: "1", names: { "eng" => "General" })
      expect(section.id).to eq("1")
      expect(section.name("eng")).to eq("General")
    end

    it "returns English name by default" do
      section = described_class.new(id: "1",
                                    names: {
                                      "eng" => "General", "fra" => "Général"
                                    })
      expect(section.name).to eq("General")
    end

    it "falls back to English for unknown language" do
      section = described_class.new(id: "1", names: { "eng" => "General" })
      expect(section.name("deu")).to eq("General")
    end
  end

  describe "hierarchical children" do
    let(:child1) do
      described_class.new(id: "103-01", names: { "eng" => "General concepts" })
    end
    let(:child2) do
      described_class.new(id: "103-02", names: { "eng" => "Functions" })
    end
    let(:parent) do
      described_class.new(id: "103", names: { "eng" => "Mathematics" },
                          children: [child1, child2])
    end

    it "has children" do
      expect(parent.children.length).to eq(2)
      expect(parent.children.map(&:id)).to eq(%w[103-01 103-02])
    end

    it "finds descendant by id" do
      found = parent.descendant_by_id("103-01")
      expect(found).not_to be_nil
      expect(found.id).to eq("103-01")
      expect(found.name("eng")).to eq("General concepts")
    end

    it "returns nil for non-existent descendant" do
      expect(parent.descendant_by_id("999")).to be_nil
    end
  end

  describe "YAML serialization" do
    it "round-trips through YAML" do
      child = described_class.new(id: "103-01", names: { "eng" => "General" })
      parent = described_class.new(id: "103", names: { "eng" => "Math" },
                                   children: [child])

      yaml = parent.to_yaml
      parsed = described_class.from_yaml(yaml)

      expect(parsed.id).to eq("103")
      expect(parsed.name("eng")).to eq("Math")
      expect(parsed.children.length).to eq(1)
      expect(parsed.children[0].id).to eq("103-01")
    end
  end
end
