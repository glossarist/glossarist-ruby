# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::FigureReference do
  subject(:ref) { described_class.new(entity_id: "fig-a") }

  it_behaves_like "a Glossarist::Reference"

  describe ".of_yaml" do
    it "accepts bare string form" do
      ref = described_class.of_yaml("mixed-reflection")
      expect(ref.entity_id).to eq("mixed-reflection")
      expect(ref.display).to be_nil
    end

    it "accepts object form with ref" do
      ref = described_class.of_yaml({ "ref" => "dispersion-prism" })
      expect(ref.entity_id).to eq("dispersion-prism")
    end

    it "accepts object form with display override" do
      ref = described_class.of_yaml({ "ref" => "fig-3",
                                      "display" => "Figure 3" })
      expect(ref.entity_id).to eq("fig-3")
      expect(ref.display).to eq("Figure 3")
    end

    it "accepts id key as alias for ref" do
      ref = described_class.of_yaml({ "id" => "fig-4" })
      expect(ref.entity_id).to eq("fig-4")
    end
  end

  describe "#dedup_key" do
    it "includes class name to avoid collisions with TableReference" do
      fig_ref = described_class.new(entity_id: "shared-id")
      tbl_ref = Glossarist::TableReference.new(entity_id: "shared-id")
      expect(fig_ref.dedup_key).not_to eq(tbl_ref.dedup_key)
    end

    it "is stable for same entity_id" do
      ref1 = described_class.new(entity_id: "fig-a")
      ref2 = described_class.new(entity_id: "fig-a")
      expect(ref1.dedup_key).to eq(ref2.dedup_key)
    end
  end
end

RSpec.describe "non-verbal inline mentions" do
  subject { Glossarist::ReferenceExtractor.new }

  it "extracts {{fig:id}} as FigureReference" do
    refs = subject.extract_from_text("See {{fig:mixed-reflection}}.")
    fig_refs = refs.grep(Glossarist::FigureReference)
    expect(fig_refs.length).to eq(1)
    expect(fig_refs.first.entity_id).to eq("mixed-reflection")
  end

  it "extracts {{fig:id, display}} with display override" do
    refs = subject.extract_from_text("See {{fig:mixed-reflection, Figure 7c}}.")
    fig_ref = refs.grep(Glossarist::FigureReference).first
    expect(fig_ref.entity_id).to eq("mixed-reflection")
    expect(fig_ref.display).to eq("Figure 7c")
  end

  it "extracts {{table:id}} as TableReference" do
    refs = subject.extract_from_text("See {{table:unit-conv}}.")
    tbl_refs = refs.grep(Glossarist::TableReference)
    expect(tbl_refs.length).to eq(1)
    expect(tbl_refs.first.entity_id).to eq("unit-conv")
  end

  it "extracts {{formula:id}} as FormulaReference" do
    refs = subject.extract_from_text("See {{formula:wave-eq}}.")
    fml_refs = refs.grep(Glossarist::FormulaReference)
    expect(fml_refs.length).to eq(1)
    expect(fml_refs.first.entity_id).to eq("wave-eq")
  end

  it "does not collide with cite: or urn: mentions" do
    refs = subject.extract_from_text("{{fig:x}} and {{cite:y}} and {{urn:z}}")
    expect(refs.grep(Glossarist::FigureReference).length).to eq(1)
    expect(refs.grep(Glossarist::ConceptReference).length).to eq(2)
  end
end

RSpec.describe "structural figure/table/formula references on ManagedConceptData" do
  it "loads figures from YAML (bare string + object form)" do
    data = Glossarist::ManagedConceptData.of_yaml(
      "figures" => ["fig-a", { "ref" => "fig-b", "display" => "Figure B" }],
    )
    expect(data.figures.map(&:entity_id)).to eq(%w[fig-a fig-b])
    expect(data.figures.last.display).to eq("Figure B")
  end

  it "loads tables from YAML" do
    data = Glossarist::ManagedConceptData.of_yaml("tables" => ["tbl-1"])
    expect(data.tables.map(&:entity_id)).to eq(["tbl-1"])
  end

  it "loads formulas from YAML" do
    data = Glossarist::ManagedConceptData.of_yaml("formulas" => ["fml-1"])
    expect(data.formulas.map(&:entity_id)).to eq(["fml-1"])
  end

  it "round-trips structural references through YAML" do
    data = Glossarist::ManagedConceptData.of_yaml(
      "figures" => ["fig-a", { "ref" => "fig-b", "display" => "Figure B" }],
    )
    restored = Glossarist::ManagedConceptData.from_yaml(data.to_yaml)
    expect(restored.figures.map(&:entity_id)).to eq(%w[fig-a fig-b])
    expect(restored.figures.last.display).to eq("Figure B")
  end

  it "serializes bare strings for refs without display" do
    data = Glossarist::ManagedConceptData.new
    data.figures = [Glossarist::FigureReference.new(entity_id: "simple")]
    yaml = data.to_yaml
    expect(yaml).to include("simple")
    expect(yaml).not_to include("ref:")
  end
end

# TableReference and FormulaReference inherit the Reference protocol and
# the dedup_key implementation from NonVerbalReference. The shared example
# verifies the protocol contract; dedup_key collision-avoidance is covered
# by FigureReference's spec above (same code path, different subclass).
RSpec.describe Glossarist::TableReference do
  subject(:ref) { described_class.new(entity_id: "tbl-1") }

  it_behaves_like "a Glossarist::Reference"
end

RSpec.describe Glossarist::FormulaReference do
  subject(:ref) { described_class.new(entity_id: "fml-1") }

  it_behaves_like "a Glossarist::Reference"
end
