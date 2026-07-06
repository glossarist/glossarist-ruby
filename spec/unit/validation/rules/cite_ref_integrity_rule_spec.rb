# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::CiteRefIntegrityRule do
  subject(:rule) { described_class.new }

  def make_concept(id:, langs: {}, sources: [])
    mc = Glossarist::ManagedConcept.new(data: { id: id })
    mc.sources = sources if sources.any?
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

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  def make_context(concept, concept_ids: nil)
    ds = make_dataset_context(tmpdir)
    ds.add_concept(concept)
    (concept_ids || []).each { |id| ds.add_concept(make_managed_concept(id: id)) }
    make_concept_context(concept, collection_context: ds)
  end

  describe "unique source ids" do
    it "passes when all source ids are unique" do
      a = Glossarist::ConceptSource.new(
        id: "a",
        type: "authoritative",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "X")),
      )
      b = Glossarist::ConceptSource.new(
        id: "b",
        type: "authoritative",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "Y")),
      )
      mc = make_concept(id: "1", sources: [a, b])
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end

    it "warns when two concept-level sources share an id" do
      a = Glossarist::ConceptSource.new(
        id: "foo",
        type: "authoritative",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "X")),
      )
      b = Glossarist::ConceptSource.new(
        id: "foo",
        type: "lineage",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "Y")),
      )
      mc = make_concept(id: "1", sources: [a, b])
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues.length).to eq(1)
      expect(issues.first.message).to match(/duplicate source id 'foo'/)
      expect(issues.first.code).to eq("GLS-110")
    end

    it "warns when a concept-level and l10n-level source share an id" do
      a = Glossarist::ConceptSource.new(
        id: "dup",
        type: "authoritative",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "X")),
      )
      b = Glossarist::ConceptSource.new(
        id: "dup",
        type: "lineage",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "Y")),
      )
      mc = make_concept(id: "1", sources: [a],
                        langs: { eng: { sources: [b] } })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      dup_issues = issues.select { |i| i.message.include?("duplicate") }
      expect(dup_issues.length).to eq(1)
    end

    it "ignores sources without an id" do
      a = Glossarist::ConceptSource.new(
        type: "authoritative",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "X")),
      )
      b = Glossarist::ConceptSource.new(
        type: "lineage",
        origin: Glossarist::Citation.new(ref: Glossarist::Citation::Ref.new(source: "Y")),
      )
      mc = make_concept(id: "1", sources: [a, b])
      ctx = make_context(mc)
      expect(rule.check(ctx)).to be_empty
    end
  end

  describe "unresolved cite: mentions" do
    it "passes when every cite mention resolves to a source" do
      mc = make_concept(id: "1", langs: {
                          eng: {
                            definition: [{ "content" => "See {{cite:iso-7301}}." }],
                            sources: [{
                              "id" => "iso-7301",
                              "type" => "authoritative",
                              "origin" => { "ref" => { "source" => "ISO",
                                                       "id" => "7301" } },
                            }],
                          },
                        })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      cite_issues = issues.select { |i| i.message.include?("cite:") }
      expect(cite_issues).to be_empty
    end

    it "warns when a cite mention has no matching source" do
      mc = make_concept(id: "1", langs: {
                          eng: {
                            definition: [{ "content" => "See {{cite:nonexistent}}." }],
                          },
                        })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues.length).to eq(1)
      expect(issues.first.message).to match(/does not resolve/)
    end

    it "passes when there are no cite: mentions" do
      mc = make_concept(id: "1", langs: {
                          eng: {
                            definition: [{ "content" => "See {{200}}." }],
                          },
                        })
      ctx = make_context(mc)
      issues = rule.check(ctx)
      expect(issues.select { |i| i.message.include?("cite:") }).to be_empty
    end
  end
end
