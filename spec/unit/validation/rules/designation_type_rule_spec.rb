# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::DesignationTypeRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }
  let(:valid_types) { Glossarist::Designation::SERIALIZED_TYPES.values.grep(String).uniq }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-207")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  it "returns no issues when all terms have a recognized type" do
    mc = make_managed_concept(id: "x", langs: {
                                eng: { terms: [{ "type" => "expression", "designation" => "t",
                                                 "normative_status" => "preferred" }] },
                              })
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc)).to be_empty
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags a term with an unrecognized designation type" do
    # Bypass Designation::Base.of_yaml (which rejects unknown types at
    # load time) by directly constructing an Expression and overriding
    # its type to simulate an unknown type sneaking through.
    bad_term = Glossarist::Designation::Expression.new(
      designation: "u", normative_status: "preferred",
    )
    bad_term.type = "invented"

    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").data.terms = [
      *mc.localization("eng").data.terms,
      bad_term,
    ]
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("invented")
    expect(issues.first.suggestion).to include(valid_types.first)
  end
end
