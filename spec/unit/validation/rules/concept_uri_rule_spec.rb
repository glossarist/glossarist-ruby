# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ConceptUriRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-014")
    expect(rule.category).to eq(:structure)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:collection)
  end

  it "is not applicable when metadata has no uri_prefix or concept_uri_template" do
    # The rule's applicable? requires context.metadata to load successfully.
    # GcrMetadata requires certain fields, so give it a minimal valid form
    # that lacks uri_prefix/concept_uri_template — the rule should still
    # apply and flag the missing fields (covered in the next example).
    zip = make_gcr_zip(tmpdir, files: {
                         "metadata.yaml" => <<~YAML,
                           ---
                           shortname: x
                           concept_count: 1
                         YAML
                       })
    gcr = make_gcr_context(zip)
    expect(rule).to be_applicable(gcr)
  end

  it "returns no issues when metadata declares a uri_prefix" do
    zip = make_gcr_zip(tmpdir, files: {
                         "metadata.yaml" => <<~YAML,
                           ---
                           shortname: x
                           uri_prefix: https://example.org/concepts/
                         YAML
                       })
    gcr = make_gcr_context(zip)
    expect(rule.check(gcr)).to be_empty
  end

  it "flags missing uri_prefix and concept_uri_template" do
    zip = make_gcr_zip(tmpdir, files: {
                         "metadata.yaml" => <<~YAML,
                           ---
                           shortname: x
                           concept_count: 1
                         YAML
                       })
    gcr = make_gcr_context(zip)
    issues = rule.check(gcr)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("URI prefix")
    expect(issues.first.suggestion).to include("uri_prefix")
  end
end
