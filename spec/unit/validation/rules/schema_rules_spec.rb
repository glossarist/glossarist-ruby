# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Schema rules" do
  def make_concept(id:, langs: {}, **overrides)
    mc = Glossarist::ManagedConcept.new(data: { id: id }.merge(overrides))
    langs.each do |lang, opts|
      terms = opts[:terms] || [{ "type" => "expression",
                                 "designation" => "test", "normative_status" => "preferred" }]
      data = {
        "language_code" => lang.to_s,
        "terms" => terms,
        "definition" => opts[:definition] || [{ "content" => "a definition" }],
        "entry_status" => opts[:entry_status] || "valid",
      }
      data["sources"] = opts[:sources] if opts[:sources]
      l10n = Glossarist::LocalizedConcept.of_yaml({ "data" => data })
      mc.add_localization(l10n)
    end
    mc
  end

  def make_context(concept)
    asset_index = Glossarist::Validation::AssetIndex.new
    bib_index = Glossarist::Validation::BibliographyIndex.new
    concept_ids = Set.new([concept.data&.id&.to_s].compact)
    cc = instance_double(Glossarist::Validation::Rules::DatasetContext,
                         asset_index: asset_index,
                         bibliography_index: bib_index,
                         concept_ids: concept_ids,
                         declared_languages: %w[eng],
                         metadata: nil,
                         gcr?: false)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept,
      file_name: "concept-#{concept.data.id}.yaml",
      collection_context: cc,
    )
  end

  describe Glossarist::Validation::Rules::ConceptStatusRule do
    subject(:rule) { described_class.new }

    it "flags invalid concept status" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" },
                                          status: "invalid_status")
      mc.add_localization(
        Glossarist::LocalizedConcept.of_yaml({
                                               "data" => {
                                                 "language_code" => "eng",
                                                 "terms" => [{
                                                   "type" => "expression", "designation" => "t"
                                                 }],
                                               },
                                             }),
      )
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-201")
    end
  end

  describe Glossarist::Validation::Rules::SourceEnumRule do
    subject(:rule) { described_class.new }

    it "flags invalid source type" do
      mc = make_concept(id: "1", langs: {
                          eng: { sources: [{ "type" => "invalid_type", "origin" => { "text" => "ref" } }] },
                        })
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-202")
    end

    it "flags invalid source status" do
      mc = make_concept(id: "1", langs: {
                          eng: { sources: [{ "type" => "authoritative", "status" => "bad_status" }] },
                        })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-203")
    end

    it "passes for valid source type and status" do
      mc = make_concept(id: "1", langs: {
                          eng: { sources: [{ "type" => "authoritative" }] },
                        })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::RelatedConceptRule do
    subject(:rule) { described_class.new }

    it "flags invalid related concept type" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" },
                                          related: [Glossarist::RelatedConcept.new(
                                            type: "invalid", content: "x",
                                          )])
      mc.add_localization(
        Glossarist::LocalizedConcept.of_yaml({
                                               "data" => {
                                                 "language_code" => "eng",
                                                 "terms" => [{
                                                   "type" => "expression", "designation" => "t"
                                                 }],
                                               },
                                             }),
      )
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-200")
    end

    it "passes for valid related concept type" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" },
                                          related: [Glossarist::RelatedConcept.new(
                                            type: "supersedes", content: "x",
                                          )])
      mc.add_localization(
        Glossarist::LocalizedConcept.of_yaml({
                                               "data" => {
                                                 "language_code" => "eng",
                                                 "terms" => [{
                                                   "type" => "expression", "designation" => "t"
                                                 }],
                                               },
                                             }),
      )
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end
end
