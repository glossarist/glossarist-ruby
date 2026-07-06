# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ImageReferenceRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-103")
    expect(rule.category).to eq(:references)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when a definition has no image references" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { definition: [{ "content" => "a plain definition" }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags an image::...[] reference whose path is not in images/" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { definition: [{ "content" => "Diagram: image::figures/missing.png[]" }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    # image::...[] path is "figures/missing.png" — both GLS-103 and GLS-104
    # may flag it depending on asset_index; verify at least one issue is
    # raised with the unresolved path.
    expect(issues).not_to be_empty
    expect(issues.first.message).to include("figures/missing.png")
  end
end
