# frozen_string_literal: true

require "spec_helper"

# Aggregate spec for integrity-family rules. Each rule also has a dedicated
# _spec.rb (added in batch 4) with richer coverage using real GCR-context
# fixtures. This file is retained as an additional smoke test using the
# ValidationRuleSpecHelper's make_gcr_zip / make_gcr_context factories.

RSpec.describe "Integrity rules" do
  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  describe Glossarist::Validation::Rules::ConceptCountRule do
    subject(:rule) { described_class.new }

    it "flags when concept_count doesn't match actual count" do
      zip = make_gcr_zip(tmpdir, files: {
                           "metadata.yaml" => <<~YAML,
                             ---
                             shortname: test
                             concept_count: 5
                           YAML
                         })
      gcr = make_gcr_context(zip)
      gcr.add_concept(make_managed_concept(id: "1"))
      expect(rule).to be_applicable(gcr)
      issues = rule.check(gcr)
      expect(issues).not_to be_empty
      expect(issues.first.code).to eq("GLS-011")
    end

    it "passes when concept_count matches" do
      zip = make_gcr_zip(tmpdir, files: {
                           "metadata.yaml" => <<~YAML,
                             ---
                             shortname: test
                             concept_count: 2
                           YAML
                         })
      gcr = make_gcr_context(zip)
      gcr.add_concept(make_managed_concept(id: "1"))
      gcr.add_concept(make_managed_concept(id: "2"))
      expect(rule.check(gcr)).to be_empty
    end
  end

  describe Glossarist::Validation::Rules::ConceptUriRule do
    subject(:rule) { described_class.new }

    it "warns when no uri_prefix in metadata" do
      zip = make_gcr_zip(tmpdir, files: {
                           "metadata.yaml" => <<~YAML,
                             ---
                             shortname: test
                             concept_count: 1
                           YAML
                         })
      gcr = make_gcr_context(zip)
      expect(rule).to be_applicable(gcr)
      issues = rule.check(gcr)
      expect(issues).not_to be_empty
      expect(issues.first.message).to include("no concept URI")
    end

    it "passes when uri_prefix is set" do
      zip = make_gcr_zip(tmpdir, files: {
                           "metadata.yaml" => <<~YAML,
                             ---
                             shortname: test
                             concept_count: 1
                             uri_prefix: urn:test
                           YAML
                         })
      gcr = make_gcr_context(zip)
      expect(rule.check(gcr)).to be_empty
    end
  end
end
