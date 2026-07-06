# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ConceptIdUniquenessRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-001-uniq")
    expect(rule.category).to eq(:structure)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:collection)
  end

  it "is not applicable when there are zero concepts" do
    expect(rule).not_to be_applicable(dataset_context)
  end

  it "returns no issues when all concept ids are unique" do
    %w[a b c].each { |id| dataset_context.add_concept(make_managed_concept(id: id)) }
    expect(rule.check(dataset_context)).to be_empty
  end

  it "flags the second occurrence of a duplicate id with the first location" do
    dataset_context.add_concept(make_managed_concept(id: "1.1"))
    dataset_context.add_concept(make_managed_concept(id: "1.2"))
    dataset_context.add_concept(make_managed_concept(id: "1.1"))
    issues = rule.check(dataset_context)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("duplicate id '1.1'")
    expect(issues.first.message).to include("concept-1.1.yaml")
  end

  it "skips concepts without an id" do
    dataset_context.add_concept(make_managed_concept(id: nil))
    dataset_context.add_concept(make_managed_concept(id: nil))
    expect(rule.check(dataset_context)).to be_empty
  end
end
