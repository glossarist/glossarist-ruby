# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DuplicateTermRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-302")
    expect(rule.category).to eq(:quality)
    expect(rule.severity).to eq("warning")
    expect(rule.scope).to eq(:collection)
  end

  it "is not applicable when there are no concepts" do
    expect(rule).not_to be_applicable(dataset_context)
  end

  it "returns no issues when preferred terms are distinct" do
    dataset_context.add_concept(make_managed_concept(id: "1", langs: {
                                                       eng: { terms: [{ "type" => "expression", "designation" => "alpha",
                                                                        "normative_status" => "preferred" }] },
                                                     }))
    dataset_context.add_concept(make_managed_concept(id: "2", langs: {
                                                       eng: { terms: [{ "type" => "expression", "designation" => "beta",
                                                                        "normative_status" => "preferred" }] },
                                                     }))
    expect(rule.check(dataset_context)).to be_empty
  end

  it "flags two concepts sharing the same preferred term in the same language" do
    dataset_context.add_concept(make_managed_concept(id: "1", langs: {
                                                       eng: { terms: [{ "type" => "expression", "designation" => "delta",
                                                                        "normative_status" => "preferred" }] },
                                                     }))
    dataset_context.add_concept(make_managed_concept(id: "2", langs: {
                                                       eng: { terms: [{ "type" => "expression", "designation" => "delta",
                                                                        "normative_status" => "preferred" }] },
                                                     }))
    issues = rule.check(dataset_context)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("'delta'")
    expect(issues.first.message).to include("1, 2")
  end

  it "treats the same term in different languages as distinct" do
    dataset_context.add_concept(make_managed_concept(id: "1", langs: {
                                                       eng: { terms: [{ "type" => "expression", "designation" => "term",
                                                                        "normative_status" => "preferred" }] },
                                                     }))
    dataset_context.add_concept(make_managed_concept(id: "2", langs: {
                                                       fra: { terms: [{ "type" => "expression", "designation" => "term",
                                                                        "normative_status" => "preferred" }] },
                                                     }))
    expect(rule.check(dataset_context)).to be_empty
  end

  it "ignores non-preferred designations" do
    dataset_context.add_concept(make_managed_concept(id: "1", langs: {
                                                       eng: { terms: [{ "type" => "expression", "designation" => "alias",
                                                                        "normative_status" => "admitted" }] },
                                                     }))
    dataset_context.add_concept(make_managed_concept(id: "2", langs: {
                                                       eng: { terms: [{ "type" => "expression", "designation" => "alias",
                                                                        "normative_status" => "deprecated" }] },
                                                     }))
    expect(rule.check(dataset_context)).to be_empty
  end
end
