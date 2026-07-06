# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::LanguageCodeFormatRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }

  let(:dataset_context) { make_dataset_context(tmpdir) }

  it "has correct metadata" do
    expect(rule.code).to eq("GLS-206")
    expect(rule.category).to eq(:schema)
    expect(rule.severity).to eq("error")
    expect(rule.scope).to eq(:concept)
  end

  %w[eng fra deu].each do |lang|
    it "returns no issues for valid ISO 639-3 code '#{lang}'" do
      mc = make_managed_concept(id: "x", langs: { lang.to_sym => {} })
      cc = make_concept_context(mc, collection_context: dataset_context)
      expect(rule.check(cc)).to be_empty
    end
  end

  it "is not applicable when the concept has no localizations" do
    mc = make_managed_concept(id: "x")
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule).not_to be_applicable(cc)
  end

  it "flags a code with wrong length" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").language_code = "en"
    cc = make_concept_context(mc, collection_context: dataset_context,
                                  file_name: "c.yaml")
    issues = rule.check(cc)
    expect(issues.length).to eq(1)
    expect(issues.first.message).to include("'en'")
    expect(issues.first.suggestion).to include("ISO 639-3")
  end

  it "flags a code with uppercase letters" do
    mc = make_managed_concept(id: "x", langs: { eng: {} })
    mc.localization("eng").language_code = "ENG"
    cc = make_concept_context(mc, collection_context: dataset_context)
    expect(rule.check(cc).length).to eq(1)
  end
end
