# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Reference rules" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

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

  def make_context(concept, extra_concept_ids: [])
    ds = make_dataset_context(tmpdir)
    ds.add_concept(concept)
    extra_concept_ids.each { |id| ds.add_concept(make_managed_concept(id: id)) }
    make_concept_context(concept, collection_context: ds)
  end

  describe Glossarist::Validation::Rules::ConceptMentionRule do
    subject(:rule) { described_class.new }

    it "warns on unresolvable concept mention" do
      mc = make_concept(id: "1", langs: {
                          eng: { definition: [{ "content" => "See {{999, missing}}" }] },
                        })
      ctx = make_context(mc, extra_concept_ids: ["1"])
      expect(rule).to be_applicable(ctx)
      issues = rule.check(ctx)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-100")
    end

    it "passes for resolvable concept mention" do
      mc = make_concept(id: "1", langs: {
                          eng: { definition: [{ "content" => "See {{1, test}}" }] },
                        })
      ctx = make_context(mc, extra_concept_ids: ["1"])
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
