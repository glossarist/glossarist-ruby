# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::UuidFormatRule do
  subject(:rule) { described_class.new }

  let(:tmpdir) { Dir.mktmpdir }
  after { FileUtils.rm_rf(tmpdir) }
  let(:dataset_context) { make_dataset_context(tmpdir) }

  def make_context(concept)
    Glossarist::Validation::Rules::ConceptContext.new(
      concept, file_name: "test.yaml", collection_context: dataset_context
    )
  end

  describe "#code" do
    it { expect(rule.code).to eq("GLS-016") }
  end

  describe "#check" do
    it "passes for valid UUID" do
      mc = make_managed_concept(id: "x")
      mc.uuid = "0ce27901-02ce-531e-8ba5-fdb136139d1a"
      expect(rule.check(make_context(mc))).to be_empty
    end

    it "passes for nil UUID" do
      mc = make_managed_concept(id: "x")
      mc.uuid = nil
      expect(rule.check(make_context(mc))).to be_empty
    end

    it "flags invalid UUID format" do
      mc = make_managed_concept(id: "x")
      mc.uuid = "not-a-uuid"
      issues = rule.check(make_context(mc))
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("not valid UUID format")
    end

    it "flags numeric-only UUID" do
      mc = make_managed_concept(id: "x")
      mc.uuid = "12345"
      expect(rule.check(make_context(mc)).size).to eq(1)
    end
  end
end
