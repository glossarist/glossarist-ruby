# frozen_string_literal: true

RSpec.describe Glossarist::DetailedDefinition do
  let(:detailed_definition) { Glossarist::DetailedDefinition.new }

  describe "#content" do
    it "returns the content" do
      detailed_definition.content = "content"
      expect(detailed_definition.content).to eq("content")
    end
  end

  describe "#sources" do
    it "returns the sources" do
      source = Glossarist::ConceptSource.from_yaml({
        "type" => "lineage",
        "status" => "identical",
        "origin" => { "ref" => { "source" => "origin" } },
        "modification" => "note",
      }.to_yaml)

      detailed_definition.sources = [
        Glossarist::ConceptSource.from_yaml({
          "type" => "lineage",
          "status" => "identical",
          "origin" => { "ref" => { "source" => "url" } },
          "modification" => "some modification",
        }.to_yaml),
        source,
      ]

      expect(detailed_definition.sources.size).to eq(2)
      expect(detailed_definition.sources.first).to be_a(Glossarist::ConceptSource)
      expect(detailed_definition.sources.first.type).to eq("lineage")
      expect(detailed_definition.sources.first.status).to eq("identical")
      expect(detailed_definition.sources.first.origin.ref.source).to eq("url")
      expect(detailed_definition.sources.first.modification).to eq("some modification")

      expect(detailed_definition.sources[1]).to be(source)
    end
  end

  describe "#examples" do
    it "defaults to an empty collection" do
      expect(detailed_definition.examples).to be_empty
    end

    it "holds DetailedDefinition instances (recursive)" do
      nested = Glossarist::DetailedDefinition.new(content: "an example inside a note")
      detailed_definition.examples = [nested]

      expect(detailed_definition.examples.size).to eq(1)
      expect(detailed_definition.examples.first).to be_a(Glossarist::DetailedDefinition)
      expect(detailed_definition.examples.first.content).to eq("an example inside a note")
    end
  end

  describe "#all_sources" do
    it "returns own sources when no examples" do
      own = Glossarist::ConceptSource.new(type: "authoritative")
      detailed_definition.sources = [own]

      expect(detailed_definition.all_sources).to eq([own])
    end

    it "aggregates sources from scoped examples" do
      own = Glossarist::ConceptSource.new(type: "authoritative")
      nested = Glossarist::ConceptSource.new(type: "lineage")
      detailed_definition.sources = [own]
      detailed_definition.examples = [
        Glossarist::DetailedDefinition.new(content: "ex", sources: [nested]),
      ]

      expect(detailed_definition.all_sources).to eq([own, nested])
    end

    it "recurses through arbitrary depth" do
      deep = Glossarist::ConceptSource.new(type: "lineage")
      inner = Glossarist::DetailedDefinition.new(
        content: "inner", sources: [deep],
      )
      outer = Glossarist::DetailedDefinition.new(
        content: "outer", examples: [inner],
      )
      detailed_definition.examples = [outer]

      expect(detailed_definition.all_sources).to eq([deep])
    end

    it "inherits recursion through V2 subclass" do
      nested_src = Glossarist::V2::ConceptSource.new(type: "authoritative")
      v2_dd = Glossarist::V2::DetailedDefinition.new(
        content: "v2 note",
        examples: [
          Glossarist::V2::DetailedDefinition.new(
            content: "v2 example", sources: [nested_src],
          ),
        ],
      )

      expect(v2_dd.all_sources).to eq([nested_src])
      expect(v2_dd.all_sources.first).to be_a(Glossarist::V2::ConceptSource)
    end

    it "inherits recursion through V3 subclass" do
      nested_src = Glossarist::V3::ConceptSource.new(type: "authoritative")
      v3_dd = Glossarist::V3::DetailedDefinition.new(
        content: "v3 note",
        examples: [
          Glossarist::V3::DetailedDefinition.new(
            content: "v3 example", sources: [nested_src],
          ),
        ],
      )

      expect(v3_dd.all_sources).to eq([nested_src])
      expect(v3_dd.all_sources.first).to be_a(Glossarist::V3::ConceptSource)
    end
  end

  describe "#text_content" do
    it "returns own content when no examples" do
      detailed_definition.content = "note text"
      expect(detailed_definition.text_content).to eq(["note text"])
    end

    it "aggregates content from scoped examples in order" do
      detailed_definition.content = "note"
      detailed_definition.examples = [
        Glossarist::DetailedDefinition.new(content: "example 1"),
        Glossarist::DetailedDefinition.new(content: "example 2"),
      ]

      expect(detailed_definition.text_content).to eq(["note", "example 1",
                                                      "example 2"])
    end

    it "skips nil content but still descends into examples" do
      detailed_definition.content = nil
      detailed_definition.examples = [
        Glossarist::DetailedDefinition.new(content: "only the example"),
      ]

      expect(detailed_definition.text_content).to eq(["only the example"])
    end

    it "recurses through arbitrary depth" do
      detailed_definition.content = "outer"
      detailed_definition.examples = [
        Glossarist::DetailedDefinition.new(
          content: "middle",
          examples: [Glossarist::DetailedDefinition.new(content: "inner")],
        ),
      ]

      expect(detailed_definition.text_content).to eq(%w[outer middle inner])
    end
  end

  describe "#to_yaml" do
    it "returns the yaml representation" do
      detailed_definition.content = "content"
      detailed_definition.sources = [
        Glossarist::ConceptSource.from_yaml({
          type: "lineage",
          status: "identical",
          origin: { "ref" => { "source" => "origin" } },
          modification: "some modification",
        }.to_yaml),
      ]

      expected_yaml = <<~YAML
        ---
        content: content
        sources:
        - origin:
            ref:
              source: origin
          status: identical
          type: lineage
          modification: some modification
      YAML

      expect(detailed_definition.to_yaml).to eq(expected_yaml)
    end

    it "omits examples when empty" do
      detailed_definition.content = "content"
      expect(detailed_definition.to_yaml).to eq("---\ncontent: content\n")
    end

    it "round-trips scoped examples inside a note" do
      note = Glossarist::DetailedDefinition.new(
        content: "Resistance depends on dimensions, material, and temperature.",
      )
      note.examples = [
        Glossarist::DetailedDefinition.new(
          content: "At 20 °C, copper resistivity is about 1.68 × 10⁻⁸ Ω·m.",
        ),
        Glossarist::DetailedDefinition.new(
          content: "For 1 m of 1 mm² copper wire, R ≈ 0.017 Ω.",
        ),
      ]

      round_tripped = Glossarist::DetailedDefinition.from_yaml(note.to_yaml)
      expected_contents = [
        "At 20 °C, copper resistivity is about 1.68 × 10⁻⁸ Ω·m.",
        "For 1 m of 1 mm² copper wire, R ≈ 0.017 Ω.",
      ]

      expect(round_tripped.content).to eq(note.content)
      expect(round_tripped.examples.size).to eq(2)
      expect(round_tripped.examples.map(&:content)).to eq(expected_contents)
      expect(round_tripped.examples).to all(be_a(Glossarist::DetailedDefinition))
    end

    it "preserves examples-of-examples (bounded recursion)" do
      inner = Glossarist::DetailedDefinition.new(content: "inner")
      outer = Glossarist::DetailedDefinition.new(content: "outer")
      outer.examples = [inner]
      note = Glossarist::DetailedDefinition.new(content: "note")
      note.examples = [outer]

      round_tripped = Glossarist::DetailedDefinition.from_yaml(note.to_yaml)

      expect(round_tripped.examples.first.content).to eq("outer")
      expect(round_tripped.examples.first.examples.first.content).to eq("inner")
    end
  end

  describe "V2 serialization" do
    it "round-trips scoped examples through V2::DetailedDefinition" do
      note = Glossarist::V2::DetailedDefinition.new(
        content: "note with a scoped example",
      )
      note.examples = [
        Glossarist::V2::DetailedDefinition.new(content: "v2 scoped example"),
      ]

      round_tripped = Glossarist::V2::DetailedDefinition.from_yaml(note.to_yaml)

      expect(round_tripped.examples.first).to be_a(Glossarist::V2::DetailedDefinition)
      expect(round_tripped.examples.first.content).to eq("v2 scoped example")
    end
  end

  describe "V3 serialization" do
    it "round-trips scoped examples through V3::DetailedDefinition" do
      note = Glossarist::V3::DetailedDefinition.new(
        content: "note with a scoped example",
      )
      note.examples = [
        Glossarist::V3::DetailedDefinition.new(content: "v3 scoped example"),
      ]

      round_tripped = Glossarist::V3::DetailedDefinition.from_yaml(note.to_yaml)

      expect(round_tripped.examples.first).to be_a(Glossarist::V3::DetailedDefinition)
      expect(round_tripped.examples.first.content).to eq("v3 scoped example")
    end
  end
end
