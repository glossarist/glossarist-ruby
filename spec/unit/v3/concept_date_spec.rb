# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::V3::ConceptDate do
  # The v3 schema (`concept-model/schemas/v3/concept.yaml`) declares
  # `concept_date.date` as `type: string, format: date`, which accepts
  # any date string — full ISO 8601 datetime, calendar date, or
  # year-only. The base Glossarist::ConceptDate types `date` as
  # `:date_time`, which fails on year-only strings. V3::ConceptDate
  # exists to fix this.
  #
  # See BUG_REPORT.md for the full investigation.

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
  end

  describe "integration with v3 model hierarchy" do
    it "is used by V3::ConceptData for the dates collection" do
      data = Glossarist::V3::ConceptData.new(language_code: "eng")
      data.dates = [
        described_class.new(type: "accepted", date: "1970-1989"),
        described_class.new(type: "retired", date: "2016"),
      ]

      yaml = data.to_yaml
      restored = Glossarist::V3::ConceptData.from_yaml(yaml)

      expect(restored.dates.length).to eq(2)
      expect(restored.dates.first.date).to eq("1970-1989")
      expect(restored.dates.last.date).to eq("2016")
    end

    it "is used by V3::ManagedConcept for the dates collection" do
      mc = Glossarist::V3::ManagedConcept.new(id: "1-1-000")
      mc.dates = [described_class.new(type: "accepted", date: "1970-1989")]

      yaml = mc.to_yaml
      restored = Glossarist::V3::ManagedConcept.from_yaml(yaml)

      expect(restored.dates.first.date).to eq("1970-1989")
    end
  end

  describe "configuration" do
    it "is reachable as a constant in the V3 namespace" do
      expect(described_class).to eq(Glossarist::V3::ConceptDate)
      expect(described_class.ancestors).to include(Glossarist::ConceptDate)
    end
  end
end
