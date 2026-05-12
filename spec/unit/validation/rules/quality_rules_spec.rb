# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Quality rules" do
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

  describe Glossarist::Validation::Rules::PreferredTermRule do
    subject(:rule) { described_class.new }

    it "warns when no term is preferred" do
      mc = make_concept(id: "1", langs: {
                          eng: { terms: [{ "type" => "expression", "designation" => "test" }] },
                        })
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-301")
    end

    it "passes when a term is preferred" do
      mc = make_concept(id: "1", langs: { eng: {} })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::DuplicateTermRule do
    subject(:rule) { described_class.new }

    it "warns on duplicate preferred terms across concepts" do
      c1 = make_concept(id: "1", langs: { eng: {} })
      c2 = make_concept(id: "2", langs: { eng: {} })
      ctx = instance_double(Glossarist::Validation::Rules::DatasetContext,
                            concepts: [c1, c2])
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-302")
    end

    it "passes when terms are unique across concepts" do
      c1 = make_concept(id: "1", langs: { eng: {} })
      c2 = make_concept(id: "2", langs: {
                          eng: { terms: [{ "type" => "expression", "designation" => "different", "normative_status" => "preferred" }] },
                        })
      ctx = instance_double(Glossarist::Validation::Rules::DatasetContext,
                            concepts: [c1, c2])
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::DefinitionContentRule do
    subject(:rule) { described_class.new }

    it "warns on empty definition content" do
      mc = make_concept(id: "1", langs: {
                          eng: { definition: [{ "content" => "" }] },
                        })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-300")
    end

    it "passes for non-empty definition" do
      mc = make_concept(id: "1", langs: { eng: {} })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::AuthoritativeSourceRule do
    subject(:rule) { described_class.new }

    it "warns when no authoritative source is defined" do
      mc = make_concept(id: "1", langs: {
                          eng: { sources: [{ "type" => "lineage", "origin" => { "text" => "ref" } }] },
                        })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-306")
    end

    it "passes when authoritative source is present" do
      mc = make_concept(id: "1", langs: {
                          eng: { sources: [{ "type" => "authoritative" }] },
                        })
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end
end
