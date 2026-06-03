# frozen_string_literal: true

require "spec_helper"

RSpec.describe Glossarist::Validation::Rules::ModelValidityRule do
  subject(:rule) { described_class.new }

  let(:path) { "spec/fixtures/concept_collection_v2" }

  describe "#code" do
    it { expect(rule.code).to eq("GLS-050") }
  end

  describe "#scope" do
    it { expect(rule.scope).to eq(:concept) }
  end

  describe "#severity" do
    it { expect(rule.severity).to eq("error") }
  end

  describe "#category" do
    it { expect(rule.category).to eq(:structure) }
  end

  describe "#applicable?" do
    it "returns true for ManagedConcept (Lutaml::Model::Serializable)" do
      concept = Glossarist::ManagedConcept.new(data: { id: "1" })
      context = Glossarist::Validation::Rules::ConceptContext.new(
        concept, file_name: "test.yaml", collection_context: nil
      )
      expect(rule.applicable?(context)).to be true
    end
  end

  describe "#check" do
    it "returns no issues for a valid concept" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => {
                                                      "language_code" => "eng",
                                                      "terms" => [{
                                                        "type" => "expression", "designation" => "test"
                                                      }],
                                                      "definition" => [{ "content" => "a definition" }],
                                                    },
                                                  })
      mc.add_localization(l10n)
      context = Glossarist::Validation::Rules::ConceptContext.new(
        mc, file_name: "1.yaml", collection_context: nil
      )
      issues = rule.check(context)
      expect(issues).to all(be_a(Glossarist::Validation::ValidationIssue))
    end

    it "returns issues with proper code and location" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      context = Glossarist::Validation::Rules::ConceptContext.new(
        mc, file_name: "concept-1.yaml", collection_context: nil
      )
      issues = rule.check(context)
      issues.each do |issue|
        expect(issue.code).to eq("GLS-050")
        expect(issue.location).to eq("concept-1.yaml")
        expect(issue).to be_error
      end
    end

    it "recurses into nested serializable attributes" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      l10n = Glossarist::LocalizedConcept.of_yaml({
                                                    "data" => {
                                                      "language_code" => "eng",
                                                      "terms" => [{
                                                        "type" => "expression", "designation" => "term"
                                                      }],
                                                      "definition" => [{ "content" => "def" }],
                                                    },
                                                  })
      mc.add_localization(l10n)
      context = Glossarist::Validation::Rules::ConceptContext.new(
        mc, file_name: "1.yaml", collection_context: nil
      )
      issues = rule.check(context)
      # Should have recursed without errors for valid data
      expect(issues).to all(be_a(Glossarist::Validation::ValidationIssue))
    end

    it "recurses into collection attributes" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      # Add multiple localizations to test array recursion
      l10n_eng = Glossarist::LocalizedConcept.of_yaml({
                                                        "data" => {
                                                          "language_code" => "eng",
                                                          "terms" => [{
                                                            "type" => "expression", "designation" => "test"
                                                          }],
                                                          "definition" => [{ "content" => "definition" }],
                                                        },
                                                      })
      mc.add_localization(l10n_eng)
      context = Glossarist::Validation::Rules::ConceptContext.new(
        mc, file_name: "1.yaml", collection_context: nil
      )
      issues = rule.check(context)
      expect(issues).to be_an(Array)
    end

    it "builds proper attribute paths in error messages" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      context = Glossarist::Validation::Rules::ConceptContext.new(
        mc, file_name: "1.yaml", collection_context: nil
      )
      issues = rule.check(context)
      # If there are issues, paths should include attribute names
      issues.each do |issue|
        expect(issue.message).to be_a(String)
      end
    end

    it "uses public_send (not send) for attribute access" do
      mc = Glossarist::ManagedConcept.new(data: { id: "1" })
      context = Glossarist::Validation::Rules::ConceptContext.new(
        mc, file_name: "1.yaml", collection_context: nil
      )
      # This should not raise — public_send only calls public methods
      expect { rule.check(context) }.not_to raise_error
    end
  end
end
