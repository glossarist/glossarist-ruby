# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::ConceptDate do
  # The v3 schema (`concept-model/schemas/v3/concept.yaml`) declares
  # `concept_date.date` as `type: string, format: date`, which accepts any
  # date string — full ISO 8601 datetime, calendar date, or year-only.
  # The base Glossarist::ConceptDate types `date` as `:date_time`, which
  # silently drops values it cannot parse as a DateTime. V3::ConceptDate
  # exists to round-trip the full v3-allowed range.

  describe "round-trip" do
    it "preserves year-only strings like '2023'" do
      cd = described_class.new(type: "retired", date: "2023")
      restored = described_class.from_yaml(cd.to_yaml)
      expect(restored.date).to eq("2023")
      expect(restored.type).to eq("retired")
    end

    it "preserves year ranges like '1970-1989'" do
      cd = described_class.new(type: "accepted", date: "1970-1989")
      restored = described_class.from_yaml(cd.to_yaml)
      expect(restored.date).to eq("1970-1989")
    end

    it "preserves calendar dates like '2020-01-01'" do
      cd = described_class.new(type: "accepted", date: "2020-01-01")
      restored = described_class.from_yaml(cd.to_yaml)
      expect(restored.date).to eq("2020-01-01")
    end

    it "preserves full ISO 8601 datetime strings" do
      iso = "2020-01-01T00:00:00+00:00"
      cd = described_class.new(type: "accepted", date: iso)
      restored = described_class.from_yaml(cd.to_yaml)
      expect(restored.date).to eq(iso)
    end

    it "preserves a nil date" do
      cd = described_class.new(type: "accepted", date: nil)
      restored = described_class.from_yaml(cd.to_yaml)
      expect(restored.date).to be_nil
      expect(restored.type).to eq("accepted")
    end
  end

  describe "to_yaml_date" do
    it "returns the string date unchanged" do
      cd = described_class.new(type: "accepted", date: "1970-1989")
      expect(cd.to_yaml_date).to eq("1970-1989")
    end

    it "returns nil when date is nil" do
      cd = described_class.new(type: "accepted", date: nil)
      expect(cd.to_yaml_date).to be_nil
    end
  end

  describe "integration with V3::ConceptData" do
    it "uses V3::ConceptDate for the dates collection" do
      data = Glossarist::V3::ConceptData.new(language_code: "eng")
      data.dates = [
        described_class.new(type: "accepted", date: "1970-1989"),
        described_class.new(type: "retired", date: "2016"),
      ]

      restored = Glossarist::V3::ConceptData.from_yaml(data.to_yaml)

      expect(restored.dates.length).to eq(2)
      expect(restored.dates.first).to be_a(described_class)
      expect(restored.dates.first.date).to eq("1970-1989")
      expect(restored.dates.last.date).to eq("2016")
    end
  end

  describe "integration with V3::ManagedConcept" do
    it "uses V3::ConceptDate for the dates collection" do
      mc = Glossarist::V3::ManagedConcept.new(id: "1-1-000")
      mc.dates = [described_class.new(type: "accepted", date: "1970-1989")]

      restored = Glossarist::V3::ManagedConcept.from_yaml(mc.to_yaml)

      expect(restored.dates.first).to be_a(described_class)
      expect(restored.dates.first.date).to eq("1970-1989")
    end

    it "types date_accepted as V3::ConceptDate (no silent data loss)" do
      yaml = <<~YAML
        id: 1-1-000
        date_accepted: "1970-1989"
        status: valid
      YAML

      restored = Glossarist::V3::ManagedConcept.from_yaml(yaml)

      expect(restored.date_accepted).to be_a(described_class)
      expect(restored.date_accepted.date).to eq("1970-1989")
      expect(restored.date_accepted.type).to eq("accepted")
    end

    it "round-trips an explicitly-set year-only date_accepted" do
      mc = Glossarist::V3::ManagedConcept.new(id: "1-1-001")
      mc.date_accepted = described_class.new(type: "accepted", date: "2023")

      restored = Glossarist::V3::ManagedConcept.from_yaml(mc.to_yaml)

      expect(restored.date_accepted).to be_a(described_class)
      expect(restored.date_accepted.date).to eq("2023")
    end
  end

  describe "integration with V3::LocalizedConcept" do
    it "round-trips a year-only accepted date through to_yaml/from_yaml" do
      l10n = Glossarist::V3::LocalizedConcept.new(language_code: "eng")
      l10n.data.dates = [described_class.new(type: "accepted",
                                             date: "1970-1989")]

      restored = Glossarist::V3::LocalizedConcept.from_yaml(l10n.to_yaml)

      expect(restored.date_accepted).to be_a(described_class)
      expect(restored.date_accepted.date).to eq("1970-1989")
    end

    it "does not crash on to_yaml when data.dates holds a year-only accepted date" do
      l10n = Glossarist::V3::LocalizedConcept.new(language_code: "eng")
      l10n.data.dates = [described_class.new(type: "accepted",
                                             date: "1970-1989")]

      expect { l10n.to_yaml }.not_to raise_error
    end
  end

  describe "configuration" do
    it "is reachable as a constant in the V3 namespace" do
      expect(described_class).to eq(Glossarist::V3::ConceptDate)
      expect(described_class.ancestors).to include(Glossarist::ConceptDate)
    end

    it "is registered in V3::Configuration as :concept_date" do
      resolved = Glossarist::V3::Configuration.resolve_model(:concept_date)
      expect(resolved).to eq(described_class)
    end
  end

  describe "base class behavior (regression documentation)" do
    # Documents the bug being fixed: the base Glossarist::ConceptDate types
    # `date` as `:date_time`, which silently drops year-only strings. A
    # future refactor that loosens the base type should update or remove
    # this spec so V3::ConceptDate's continued value is reconsidered.

    it "silently drops year-only strings on the base class" do
      cd = Glossarist::ConceptDate.new(type: "accepted", date: "2023")
      restored = Glossarist::ConceptDate.from_yaml(cd.to_yaml)
      expect(restored.date).to be_nil
    end
  end
end
