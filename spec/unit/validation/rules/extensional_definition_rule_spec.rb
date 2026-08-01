# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ExtensionalDefinitionRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_concept_with_definition(type:, content:, lang: "eng")
    data = Glossarist::V3::ConceptData.new(
      id: "test",
      language_code: lang,
      definition: [
        Glossarist::V3::DetailedDefinition.new(type: type, content: content),
      ],
    )
    l10n = Glossarist::V3::LocalizedConcept.new(data: data)
    mc = Glossarist::V3::ManagedConcept.new(data: Glossarist::V3::ManagedConceptData.new(id: "test"))
    mc.add_l10n(l10n)
    mc
  end

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept,
      file_name: "c.yaml",
      collection_context: dataset_context,
    )
  end

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-223")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "is not applicable when concept has no extensional definitions" do
    mc = make_concept_with_definition(
      type: "intensional",
      content: "A concept defined by its intension.",
    )
    expect(rule).not_to be_applicable(make_context(mc))
  end

  it "is applicable when at least one extensional definition exists" do
    mc = make_concept_with_definition(
      type: "extensional",
      content: "Primary colours are red, blue, and yellow.",
    )
    expect(rule).to be_applicable(make_context(mc))
  end

  describe "open-ended wording detection (ISO 704:2022 §6.4.5.1)" do
    [
      ["ellipsis",          "Primary colours are red, blue..."],
      ["etc.",              "Primary colours are red, blue, etc."],
      ["etc (no period)",   "Colours include red, etc"],
      ["and so on",         "Primary colours are red, blue, and so on"],
      ["and similar",       "Primary colours are red, blue, and similar"],
      ["and the like",      "Tools include hammer, saw, and the like"],
      ["and other",         "Fruits are apple, pear, and other produce"],
      ["and others",        "Scientists include Newton, Einstein, and others"],
      ["including",         "Tools, including hammer and saw"],
      ["such as",           "Birds such as eagle and hawk"],
      ["e.g.",              "Tools (e.g. hammer)"],
    ].each do |label, content|
      it "flags #{label.inspect}" do
        mc = make_concept_with_definition(type: "extensional", content: content)
        issues = rule.check(make_context(mc))
        expect(issues.length).to eq(1), "expected 1 issue for #{label}, got #{issues.length}"
        expect(issues.first.message).to include("§6.4.5.1")
      end
    end
  end

  it "does not flag exhaustive extensional definitions" do
    mc = make_concept_with_definition(
      type: "extensional",
      content: "Primary colours are red, blue, and yellow.",
    )
    expect(rule.check(make_context(mc))).to be_empty
  end

  it "does not flag intensional definitions even with open-ended wording" do
    mc = make_concept_with_definition(
      type: "intensional",
      content: "Tools include hammer, saw, etc.",
    )
    expect(rule).not_to be_applicable(make_context(mc))
  end

  it "does not flag translated definitions" do
    mc = make_concept_with_definition(
      type: "translated",
      content: "Primary colours are red, blue... and translated from English.",
    )
    expect(rule).not_to be_applicable(make_context(mc))
  end

  it "checks examples and notes too (not just definition)" do
    data = Glossarist::V3::ConceptData.new(
      id: "test",
      language_code: "eng",
      definition: [
        Glossarist::V3::DetailedDefinition.new(
          type: "intensional", content: "A normal definition.",
        ),
      ],
      examples: [
        Glossarist::V3::DetailedDefinition.new(
          type: "extensional", content: "Tools include hammer, saw, etc.",
        ),
      ],
    )
    l10n = Glossarist::V3::LocalizedConcept.new(data: data)
    mc = Glossarist::V3::ManagedConcept.new(
      data: Glossarist::V3::ManagedConceptData.new(id: "test"),
    )
    mc.add_l10n(l10n)

    issues = rule.check(make_context(mc))
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("examples[0]")
  end
end
