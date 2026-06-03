# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::ValidationResult do
  describe "#valid?" do
    it "returns true when no errors" do
      result = described_class.new
      expect(result).to be_valid
    end

    it "returns false when errors present" do
      issue = Glossarist::Validation::ValidationIssue.new(
        severity: "error", message: "something broke",
      )
      result = described_class.new(issues: [issue])
      expect(result).not_to be_valid
    end

    it "returns true when only warnings present" do
      issue = Glossarist::Validation::ValidationIssue.new(
        severity: "warning", message: "minor issue",
      )
      result = described_class.new(issues: [issue])
      expect(result).to be_valid
    end
  end

  describe "#merge" do
    it "combines errors from both results" do
      a = described_class.new(issues: [
                                Glossarist::Validation::ValidationIssue.new(
                                  severity: "error", message: "error 1",
                                ),
                              ])
      b = described_class.new(issues: [
                                Glossarist::Validation::ValidationIssue.new(
                                  severity: "error", message: "error 2",
                                ),
                              ])

      a.merge(b)
      expect(a.errors).to eq(["[ERROR] error 1", "[ERROR] error 2"])
    end

    it "combines warnings from both results" do
      a = described_class.new(issues: [
                                Glossarist::Validation::ValidationIssue.new(
                                  severity: "warning", message: "warn 1",
                                ),
                              ])
      b = described_class.new(issues: [
                                Glossarist::Validation::ValidationIssue.new(
                                  severity: "warning", message: "warn 2",
                                ),
                              ])

      a.merge(b)
      expect(a.warnings).to eq(["[WARNING] warn 1", "[WARNING] warn 2"])
    end

    it "combines errors and warnings independently" do
      a = described_class.new(issues: [
                                Glossarist::Validation::ValidationIssue.new(
                                  severity: "error", message: "e1",
                                ),
                                Glossarist::Validation::ValidationIssue.new(
                                  severity: "warning", message: "w1",
                                ),
                              ])
      b = described_class.new(issues: [
                                Glossarist::Validation::ValidationIssue.new(
                                  severity: "error", message: "e2",
                                ),
                                Glossarist::Validation::ValidationIssue.new(
                                  severity: "warning", message: "w2",
                                ),
                              ])

      a.merge(b)
      expect(a.errors).to eq(["[ERROR] e1", "[ERROR] e2"])
      expect(a.warnings).to eq(["[WARNING] w1", "[WARNING] w2"])
    end

    it "returns self for chaining" do
      a = described_class.new
      b = described_class.new
      expect(a.merge(b)).to equal(a)
    end
  end

  describe "#to_hash" do
    it "produces hash with issues serialized via lutaml-model" do
      issue = Glossarist::Validation::ValidationIssue.new(
        severity: "warning", message: "test",
      )
      result = described_class.new(issues: [issue])

      h = result.to_hash
      expect(h["issues"].length).to eq(1)
      expect(h["issues"].first).to include(
        "severity" => "warning",
        "message" => "test",
      )
    end
  end
end
