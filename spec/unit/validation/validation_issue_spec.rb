# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::ValidationIssue do
  describe "attributes" do
    it "stores severity, code, message, location, suggestion" do
      issue = described_class.new(
        severity: "error",
        code: "GLS-001",
        message: "bad id",
        location: "concept-1.yaml",
        suggestion: "fix it",
      )
      expect(issue.severity).to eq("error")
      expect(issue.code).to eq("GLS-001")
      expect(issue.message).to eq("bad id")
      expect(issue.location).to eq("concept-1.yaml")
      expect(issue.suggestion).to eq("fix it")
    end
  end

  describe "#error?" do
    it "returns true for error severity" do
      issue = described_class.new(severity: "error", message: "x")
      expect(issue).to be_error
    end

    it "returns false for warning severity" do
      issue = described_class.new(severity: "warning", message: "x")
      expect(issue).not_to be_error
    end
  end

  describe "#warning?" do
    it "returns true for warning severity" do
      issue = described_class.new(severity: "warning", message: "x")
      expect(issue).to be_warning
    end
  end

  describe "#info?" do
    it "returns true for info severity" do
      issue = described_class.new(severity: "info", message: "x")
      expect(issue).to be_info
    end
  end

  describe "#to_s" do
    it "formats with severity, code, location, and message" do
      issue = described_class.new(
        severity: "error", code: "GLS-001",
        message: "bad", location: "f.yaml"
      )
      expect(issue.to_s).to eq("[ERROR] [GLS-001] f.yaml:  bad")
    end

    it "includes suggestion when present" do
      issue = described_class.new(
        severity: "error", code: "GLS-001",
        message: "bad", location: "f.yaml",
        suggestion: "fix it"
      )
      expect(issue.to_s).to include("(fix it)")
    end
  end
end
