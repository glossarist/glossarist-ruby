# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Reference rules" do
  def make_concept(id:, langs: {})
    mc = Glossarist::ManagedConcept.new(data: { id: id })
    langs.each do |lang, opts|
      terms = opts[:terms] || [{ "type" => "expression",
                                 "designation" => "test", "normative_status" => "preferred" }]
      data = {
        "language_code" => lang.to_s,
        "terms" => terms,
        "definition" => opts[:definition] || [{ "content" => "a definition" }],
        "entry_status" => opts[:entry_status] || "valid",
      }
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

  describe Glossarist::Validation::Rules::ConceptMentionRule do
    subject(:rule) { described_class.new }

    it "warns on unresolvable concept mention" do
      mc = make_concept(id: "1", langs: {
                          eng: { definition: [{ "content" => "See {{missing, 999}}" }] },
                        })
      ctx = make_context(mc, concept_ids: Set.new(["1"]))
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-100")
    end

    it "passes for resolvable concept mention" do
      mc = make_concept(id: "1", langs: {
                          eng: { definition: [{ "content" => "See {{test, 1}}" }] },
                        })
      ctx = make_context(mc, concept_ids: Set.new(["1"]))
      issues = rule.check(ctx)
      expect(issues).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::AsciidocXrefRule do
    subject(:rule) { described_class.new }

    it "warns on unresolved bibliography reference" do
      mc = make_concept(id: "1", langs: {
                          eng: { definition: [{ "content" => "See <<ISO_9999>>" }] },
                        })
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-102")
    end
  end

  describe Glossarist::Validation::Rules::ImageReferenceRule do
    subject(:rule) { described_class.new }

    it "warns on unresolved image reference in text" do
      mc = make_concept(id: "1", langs: {
                          eng: { definition: [{ "content" => "image::missing.png[]" }] },
                        })
      ctx = make_context(mc)
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-103")
    end
  end
end
