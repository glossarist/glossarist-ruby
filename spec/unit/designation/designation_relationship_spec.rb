# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Designation::DesignationRelationship do
  describe "YAML round-trip" do
    it "preserves type, content, and target" do
      original = described_class.new(
        type: "abbreviated_form_for",
        content: "World Wide Web",
        target: "World Wide Web",
      )
      yaml = original.to_yaml
      restored = described_class.from_yaml(yaml)

      expect(restored.type).to eq("abbreviated_form_for")
      expect(restored.content).to eq("World Wide Web")
      expect(restored.target).to eq("World Wide Web")
    end

    it "works without optional fields" do
      dr = described_class.new(type: "short_form_for", target: "application")
      yaml = dr.to_yaml
      restored = described_class.from_yaml(yaml)

      expect(restored.type).to eq("short_form_for")
      expect(restored.target).to eq("application")
      expect(restored.content).to be_nil
    end
  end

  describe "type validation" do
    Glossarist::GlossaryDefinition::DESIGNATION_RELATIONSHIP_TYPES.each do |rel_type|
      it "accepts #{rel_type} type" do
        dr = described_class.new(type: rel_type, target: "something")
        expect(dr.type).to eq(rel_type)
      end
    end
  end

  describe "integration with Designation::Base" do
    it "designation related attribute accepts DesignationRelationship objects" do
      abbr = Glossarist::Designation::Abbreviation.new(
        designation: "LED", type: "abbreviation", acronym: true,
      )
      abbr.related = [
        described_class.new(
          type: "abbreviated_form_for",
          target: "Light Emitting Diode",
        ),
      ]

      expect(abbr.related.size).to eq(1)
      expect(abbr.related.first.type).to eq("abbreviated_form_for")
      expect(abbr.related.first.target).to eq("Light Emitting Diode")
    end

    it "round-trips through YAML with target preserved" do
      abbr = Glossarist::Designation::Abbreviation.new(
        designation: "LED", type: "abbreviation", acronym: true,
      )
      abbr.related = [
        described_class.new(
          type: "abbreviated_form_for",
          target: "Light Emitting Diode",
        ),
      ]

      yaml = abbr.to_yaml
      restored = Glossarist::Designation::Abbreviation.from_yaml(yaml)

      expect(restored.related.size).to eq(1)
      expect(restored.related.first.target).to eq("Light Emitting Diode")
    end
  end
end
