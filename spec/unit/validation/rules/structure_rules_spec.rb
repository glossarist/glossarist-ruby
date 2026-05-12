# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Structure rules" do
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

  def make_context(concept, stubs = {})
    asset_index = stubs[:asset_index] || Glossarist::Validation::AssetIndex.new
    bib_index = stubs[:bibliography_index] || Glossarist::Validation::BibliographyIndex.new
    concept_ids = stubs[:concept_ids] || Set.new([concept.data&.id&.to_s].compact)
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

  describe Glossarist::Validation::Rules::ConceptIdRule do
    subject(:rule) { described_class.new }

    it "flags concept with no id" do
      mc = Glossarist::ManagedConcept.new
      ctx = make_context(mc, concept_ids: Set.new)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-001")
    end

    it "passes for concept with valid id" do
      mc = make_concept(id: "100")
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::ConceptIdUniquenessRule do
    subject(:rule) { described_class.new }

    it "flags duplicate concept ids" do
      c1 = make_concept(id: "1", langs: { eng: {} })
      c2 = make_concept(id: "1", langs: { eng: {} })
      ctx = instance_double(Glossarist::Validation::Rules::DatasetContext,
                            concepts: [c1, c2])
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("duplicate id")
    end
  end

  describe Glossarist::Validation::Rules::LocalizationPresenceRule do
    subject(:rule) { described_class.new }

    it "flags concept with no localizations" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
    end

    it "passes for concept with localizations" do
      mc = make_concept(id: "1", langs: { eng: {} })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::EntryStatusRule do
    subject(:rule) { described_class.new }

    it "flags invalid entry_status" do
      mc = make_concept(id: "1", langs: { eng: { entry_status: "Standard" } })
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("invalid entry_status")
    end

    it "passes for valid entry_status" do
      mc = make_concept(id: "1", langs: { eng: { entry_status: "valid" } })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::TermsPresenceRule do
    subject(:rule) { described_class.new }

    it "flags localization with no terms" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => {
                                                      "language_code" => "eng",
                                                      "terms" => [],
                                                      "definition" => [{ "content" => "a definition" }],
                                                      "entry_status" => "valid",
                                                    },
                                                  })
      mc.add_localization(l10n)
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("must have at least 1 term")
    end

    it "passes for localization with terms" do
      mc = make_concept(id: "1", langs: { eng: {} })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end
end
